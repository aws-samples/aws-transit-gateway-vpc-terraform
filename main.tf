# vpcs and private/public subnets
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  count = length(var.vpc_subnet_cidrs)

  name = var.vpc_subnet_cidrs[count.index].vpc_name
  cidr = var.vpc_subnet_cidrs[count.index].vpc_cidr

  azs             = [for az_suffix in var.vpc_subnet_cidrs[count.index].az_suffixes: "${var.region}${az_suffix}"]
  private_subnets = var.vpc_subnet_cidrs[count.index].private_subnet_cidrs
  public_subnets  = var.vpc_subnet_cidrs[count.index].public_subnet_cidrs

  enable_nat_gateway = false
  enable_vpn_gateway = false
}

module "tgw" {
  source  = "terraform-aws-modules/transit-gateway/aws"
  version = "~> 2.0"

  depends_on = [ module.vpc ]

  name            = var.tgw-identifier
  description     = var.tgw-description
  amazon_side_asn = var.amazon_side_asn
  share_tgw       = false # sharing option across accounts using AWS RAM enabled by default

  # add each vpc attachment separately
  vpc_attachments = {
    vpc1 = {
      vpc_id       = module.vpc[0].vpc_id
      subnet_ids   = module.vpc[0].private_subnets
      
      transit_gateway_default_route_table_association = true
      transit_gateway_default_route_table_propagation = true

      tgw_routes = [
        {
          destination_cidr_block = module.vpc[0].vpc_cidr_block
        }
      ]
    },
    vpc2 = {
      vpc_id      = module.vpc[1].vpc_id
      subnet_ids  = module.vpc[1].private_subnets

      dns_support  = true

      transit_gateway_default_route_table_association = true
      transit_gateway_default_route_table_propagation = true

      tgw_routes = [
        {
          destination_cidr_block = module.vpc[1].vpc_cidr_block
        }
      ]
    },
  }
}

# private and public subnet route table routes to the tgw cidrs
# we are making the assumption that there are exactly 2 VPCs
locals {
  # first public and private subnets of vpc[0] pointing to vpc[1]
  private_vpc_0_to_1 = flatten([
    for route_table_id in flatten(module.vpc[0].private_route_table_ids) : {
        route_table_id = route_table_id
        tgw_cidr       = module.vpc[1].vpc_cidr_block
    }
  ])
  
  public_vpc_0_to_1 = flatten([
    for route_table_id in flatten(module.vpc[0].public_route_table_ids) : {
        route_table_id = route_table_id
        tgw_cidr       = module.vpc[1].vpc_cidr_block
    }
  ])

  # second public and private subnets of vpc[1] pointing to vpc[0]
  private_vpc_1_to_0 = flatten([
    for route_table_id in flatten(module.vpc[1].private_route_table_ids) : {
        route_table_id = route_table_id
        tgw_cidr       = module.vpc[0].vpc_cidr_block
    }
  ])

  public_vpc_1_to_0 = flatten([
    for route_table_id in flatten(module.vpc[1].public_route_table_ids) : {
        route_table_id = route_table_id
        tgw_cidr       = module.vpc[0].vpc_cidr_block
    }
  ])

  all_routes = concat(local.private_vpc_0_to_1, local.public_vpc_0_to_1, local.private_vpc_1_to_0, local.public_vpc_1_to_0)
}

resource "aws_route" "tgw-all-rt" {
  depends_on = [ module.tgw ]
  
  count = length(local.all_routes)
  
  route_table_id         = local.all_routes[count.index].route_table_id
  destination_cidr_block = local.all_routes[count.index].tgw_cidr
  gateway_id             = module.tgw.ec2_transit_gateway_id
} 
