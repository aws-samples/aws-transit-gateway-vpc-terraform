variable "region" {
  type    = string

  validation {
    condition     = can(regex("[a-z][a-z]-[a-z]+-[1-9]", var.region))
    error_message = "Must be valid AWS Region."
  }
}

variable "tgw-identifier" {
  type    = string
}

variable "tgw-description" {
  type    = string
}

variable "amazon_side_asn" {
  type = number

  validation {
    condition     = var.amazon_side_asn >= 64512 && var.amazon_side_asn <= 65534
    error_message = "Accepted values: 64512-65534."
  }
}

variable "vpc_subnet_cidrs" {
  type = list(object({
    vpc_name             = string
    vpc_cidr             = string
    private_subnet_cidrs = list(string)
    public_subnet_cidrs  = list(string)
    az_suffixes          = list(string)
  }))

  validation {
    condition = alltrue([
      for o in var.vpc_subnet_cidrs: can(cidrhost(o.vpc_cidr, 0))
    ])
    error_message = "Not a valid vpc CIDR."
  }

  validation {
    condition = alltrue([
      for o in var.vpc_subnet_cidrs: alltrue([
        for az_suffix in o.az_suffixes: contains(["a","b","c"], az_suffix)
      ])
    ])
    error_message = "Not valid az suffixes."
  }
}
