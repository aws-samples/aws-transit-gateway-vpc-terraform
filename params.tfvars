region = "eu-west-1"
tgw-identifier = "my-transit-gateway"
tgw-description = "tgw to connect main and secondary VPCs and then connect to Site-to-Site VPN connection to on-premises"

amazon_side_asn = 64532

vpc_subnet_cidrs = [
  {
    vpc_name             = "main-vpc"
    vpc_cidr             = "10.0.0.0/20"
    private_subnet_cidrs = [ "10.0.0.0/24", "10.0.1.0/24" ]
    public_subnet_cidrs  = [ "10.0.5.0/24", "10.0.6.0/24" ]
    az_suffixes          = ["a", "b", "c"]
  },
  {
    vpc_name             = "secondary-vpc"
    vpc_cidr             = "10.0.16.0/20"
    private_subnet_cidrs = [ "10.0.16.0/24", "10.0.17.0/24" ]
    public_subnet_cidrs  = [ "10.0.21.0/24", "10.0.22.0/24" ]
    az_suffixes          = ["a", "b", "c"]
  }
]
