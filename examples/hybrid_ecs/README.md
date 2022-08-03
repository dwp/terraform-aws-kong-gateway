# Hybrid Example With External Database

![architecture-diagram](https://raw.githubusercontent.com/dwp/terraform-aws-kong-gateway/main/examples/hybrid_ecs/hybrid_ecs.png)

## Description

This code will act as an example of how to call the terraform-aws-kong-gw module.
It should highlight the required inputs to get the module to deploy kong in hybrid
mode using ECS Fargate and the container in the `/docker-image/` directory. Internet access is via a proxy server. Database is being provided from outside of the module.
