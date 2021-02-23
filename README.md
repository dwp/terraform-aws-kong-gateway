# terraform-aws-kong-gateway

A terraform module for provisioning Kong GW into ec2

## Status
Prototyping - frequent commits, only a few tests

## Examples
Examples of how to use the module are in the examples directory.
Currently two examples exist `hybrid` and `hybrid_with_ingress`.

`hybrid` deploys Kong in hybrid mode

## Testing

This module uses kitchen-terraform to build an example infrastructure in AWS and
then run integration tests against it. To install you can use the `Gemfile`.
You will need Ruby 2.7 (ruby devel needed as well) installed and bundler,
then you can run `bundle install` in the repos home directory
