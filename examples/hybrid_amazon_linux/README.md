# Hybrid Example With External Database

![architecture-diagram](https://raw.githubusercontent.com/dwp/terraform-aws-kong-gateway/main/examples/hybrid_external_database/hybrid_external_amazon_linux.png)

## Description

This code will act as an example of how to call the terraform-aws-kong-gw module.
It should highlight the required inputs to get the module to deploy kong in hybrid
mode using Amazon Linux 2 (should also apply to RHEL). Internet access is via a proxy server. Database is being provided from outside of the module.
