locals {
  # Automatically load environment-level variables
  # NB: The root terragrunt.hcl file will merge common variables into inputs {}
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  common_vars      = read_terragrunt_config(find_in_parent_folders("common.hcl"))

  # Extract out common variables for reuse
  cluster_name    = "dp-prod-${local.region_vars.locals.aws_region}"
  cluster_version = "1.29"
  aws_region      = local.region_vars.locals.aws_region
}

dependency "vpc" {
  config_path = "../../vpc/default"
}

dependency "security_group_default" {
  config_path = "../../security_group/default"
}

terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v20.31.6"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

inputs = {
  cluster_name    = local.cluster_name
  cluster_version = "1.31"

  # Optional
  create_cluster_iam_role               = true
  cluster_endpoint_public_access = true
  enable_cluster_creator_admin_permissions = true

  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  vpc_id          = dependency.vpc.outputs.vpc_id
  subnet_ids      = dependency.vpc.outputs.private_subnets

  iam_role_name                      = local.cluster_name
  cluster_security_group_name        = local.cluster_name
  cluster_security_group_description = "EKS cluster security group."

  node_security_group_description     = "Security group for all nodes in the cluster."
  node_security_group_use_name_prefix = false
  iam_role_additional_policies = {
    AmazonEKSServicePolicy = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  }

  tags = merge(yamldecode(file("${get_parent_terragrunt_dir()}/files/default_tags.yaml")),
    {
      cluster     = local.cluster_name
  })

  vpc_security_group_ids                 = [dependency.security_group_default.outputs.security_group_id]
  create_cloudwatch_log_group            = true
  cloudwatch_log_group_retention_in_days = 7
  cluster_enabled_log_types              = ["api", "audit", "scheduler", "controllerManager"]
  cluster_timeouts = {
    create = "30m",
    delete = "15m",
    update = "60m"
  }
  authentication_mode = "API_AND_CONFIG_MAP"


  cluster_security_group_additional_rules = {
    cluster_private_access_cidrs_source = {
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow private K8S API ingress from custom CIDR source."
    },
    egress_nodes_443 = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow cluster egress access to the Internet."
    }
  }

  node_security_group_additional_rules = {
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all egress to the Internet."
    },
    workers_ingress_cluster = {
      type                          = "ingress"
      from_port                     = 1025
      to_port                       = 65535
      protocol                      = "tcp"
      source_cluster_security_group = true
      description                   = "Allow workers pods to receive communication from the cluster control plane."
    },
    workers_ingress_self = {
      type        = "ingress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      self        = true
      description = "Allow node to communicate with each other."
    },
    egress_nodes_kubelet = {
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [dependency.vpc.outputs.vpc_cidr_block]
      description = "Allow workers pods to receive communication from the cluster control plane."
    }
  }

}
