locals {
  # Automatically load common variables
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))

  # Automatically load region-level variables
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl", "${path_relative_from_include()}/region-fallback.hcl"))

  # Extract the variables we need for easy access
  account_id                = local.common_vars.locals.aws_account_id
  aws_region                = local.region_vars.locals.aws_region
  aws_regions_in_use        = ["eu-north-1"]
  terraform_state_s3_region = local.common_vars.locals.terraform_state_s3_region
  terraform_state_s3_bucket = local.common_vars.locals.terraform_state_s3_bucket
}

# Generate provider blocks
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"

  # Only these AWS Account IDs may be operated on by this template
  allowed_account_ids = ["${local.account_id}"]

  assume_role {
    role_arn = "arn:aws:iam::${local.account_id}:role/dp-terraform-access"
    duration = "1h"
  }

  default_tags {
    tags = {
      ManagedBy = "terraform"
    }
  }
}

%{for region in local.aws_regions_in_use~}
provider "aws" {
  region = "${region}"
  alias  = "${region}"

  assume_role {
    role_arn = "arn:aws:iam::${local.account_id}:role/dp-terraform-access"
    duration = "1h"
  }

  # Only these AWS Account IDs may be operated on by this template
  allowed_account_ids = ["${local.account_id}"]
  
  default_tags {
    tags = {
      ManagedBy = "terraform"
    }
  }
}
%{endfor~}
EOF
}

# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"
  config = {
    encrypt = true
    bucket  = local.terraform_state_s3_bucket
    key     = "aws/${path_relative_to_include()}/terraform.tfstate"
    region  = local.terraform_state_s3_region
    acl     = "bucket-owner-full-control"
    dynamodb_table = "terraform-locks"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Configure root level variables that all resources can inherit. This is especially helpful with multi-account configs
# where terraform_remote_state data sources are placed directly into the modules.
inputs = merge(
  local.common_vars.locals,
  local.region_vars.locals,
)
