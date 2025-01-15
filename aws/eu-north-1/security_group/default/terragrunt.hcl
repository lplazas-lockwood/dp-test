locals {
  # Automatically load environment-level variables
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Extract out common variables for reuse
  region      = local.region_vars.locals.aws_region
}

dependency "vpc" {
  config_path = "../../vpc/default"
}

terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git?ref=v5.3.0"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

inputs = {
  name        = "${dependency.vpc.outputs.vpc_id}-SecurityGroupDefault"
  description = "Default security group for ${dependency.vpc.outputs.vpc_id}"
  vpc_id      = dependency.vpc.outputs.vpc_id

  tags = merge(yamldecode(file("${get_parent_terragrunt_dir()}/files/default_tags.yaml")),
    {
      Type        = "Network"
      Vpc         = dependency.vpc.outputs.vpc_id
  })

  egress_ipv6_cidr_blocks = []

  ingress_cidr_blocks = ["10.0.0.0/8"]
  ingress_rules       = ["ssh-tcp"]

  # Specific outbound rules
  egress_with_cidr_blocks = [
    # HTTP/S
    {
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule        = "http-80-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}
