# ------------------------------------------------------------------------------
# root.hcl — State backend configuration (local or S3+DynamoDB).
# Included from each layer (env, datacenter, stack). Resolves the environment from
# environment_vars.yaml and the backend from config/backend-<env>.hcl (optional activation).
# ------------------------------------------------------------------------------
locals {
  terraform_version = trimspace(file(find_in_parent_folders(".terraform-version")))

  # Environment: required to choose config/backend-<env>.hcl. If there is no YAML
  # (for example, execution outside live/), use default content to avoid breaking.
  _env_yaml_path    = find_in_parent_folders("environment_vars.yaml", "")
  _env_yaml_content = local._env_yaml_path != "" ? file(local._env_yaml_path) : "environment: dev\nclient: example"
  _env_vars         = yamldecode(local._env_yaml_content)
  environment       = lookup(local._env_vars, "environment", "dev")

  # Backend: first backend-<env>.hcl, fall back to backend-dev.hcl if it does not exist.
  # If there is no file, use local backend by default (do not store credentials here).
  _be_env  = find_in_parent_folders("config/backend-${local.environment}.hcl", "")
  _be_dev  = find_in_parent_folders("config/backend-dev.hcl", "")
  _be_path = local._be_env != "" ? local._be_env : local._be_dev

  use_remote_state = local._be_path != "" ? lookup(try(read_terragrunt_config(local._be_path).locals, {}), "backend_enabled", false) : false

  _be_cfg = local._be_path != "" && local.use_remote_state ? read_terragrunt_config(local._be_path).locals : {}

  remote_state_bucket         = lookup(local._be_cfg, "s3_bucket", "REPLACE_ME")
  remote_state_region         = lookup(local._be_cfg, "s3_region", "us-east-1")
  remote_state_dynamodb_table = lookup(local._be_cfg, "dynamodb_table", "REPLACE_ME")
  remote_state_endpoint       = lookup(local._be_cfg, "s3_endpoint", "")

  # Unique key per client/environment/path to avoid collisions across stacks.
  _client          = lookup(local._env_vars, "client", "example")
  remote_state_key = "${local._client}/${local.environment}/${path_relative_to_include()}/terraform.tfstate"

  remote_state_s3_base = {
    bucket         = local.remote_state_bucket
    key            = local.remote_state_key
    region         = local.remote_state_region
    dynamodb_table = local.remote_state_dynamodb_table
    encrypt        = true
  }

  # S3-compatible (MinIO, etc.): only applies when s3_endpoint is defined.
  remote_state_s3_compat = local.remote_state_endpoint != "" ? {
    endpoint                    = local.remote_state_endpoint
    force_path_style            = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
  } : {}
}

# Dual mode: local by default (state on disk); remote optional through backend_enabled.
# After changing backends: terragrunt init -reconfigure (and -migrate-state when needed).
# Local backend: absolute path in the stack directory (not in .terragrunt-cache).
remote_state {
  backend = local.use_remote_state ? "s3" : "local"

  generate = {
    path      = "remote_state.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = local.use_remote_state ? merge(local.remote_state_s3_base, local.remote_state_s3_compat) : {
    path = "${get_terragrunt_dir()}/state/terraform.tfstate"
  }
}

# Default lock wait time for plan/apply/destroy (avoids passing -lock-timeout manually).
terraform {
  exclude_from_copy = ["state/**"]

  before_hook "ensure_local_state_dir" {
    commands = ["plan", "apply", "destroy"]
    execute  = ["bash", "-lc", "mkdir -p ${get_terragrunt_dir()}/state"]
  }

  extra_arguments "lock_timeout" {
    commands  = get_terraform_commands_that_need_locking()
    arguments = ["-lock-timeout=5m"]
  }
}
