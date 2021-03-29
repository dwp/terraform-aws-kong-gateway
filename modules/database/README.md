# Kong Gateway: database submodule

Terraform module to create an RDS cluster. Defaults to Aurora Postgres.


## Usage
```hcl

module "database" {
  source                  = "dwp/kong-gateway/aws//modules/database"
  name                    = "kong"
  allowed_security_groups = []
  
  database_credentials = {
    username = var.postgres_config.master_user
    password = var.postgres_config.master_password
  }
  
  vpc = {
    id      = var.vpc_id
    subnets = var.subnets
    azs     = var.availability_zones
  }
}

```

## Example
```hcl
module "database" {
  source                  = "dwp/kong-gateway/aws//modules/database"
  name                    = "kong"
  environment             = "example"
  allowed_security_groups = var.allowed_security_groups
  skip_final_snapshot     = true
  encrypt_storage         = true
  
  database_credentials = {
    username = var.postgres_config.master_user
    password = var.postgres_config.master_password
  }
  
  vpc = {
    id      = var.vpc_id
    subnets = var.subnets
    azs     = var.availability_zones
  }
}
```
