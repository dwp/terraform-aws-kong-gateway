# Contributing

## Contents of this file

### For contributors
- [Running locally](#running-locally)
- [Conventions to follow](#conventions-to-follow)
- [Testing and linting](#testing-and-linting)
- [Updating Changelog](#updating-changelog)

### For maintainers
- [Releasing a new version](#releasing-a-new-version)

## Running locally

Locally source module into another Terraform code base and plan/apply as normal.

## Conventions to follow

Follow [Terraform Style Conventions](https://www.terraform.io/docs/language/syntax/style.html) and [Terraform Standard Module Structure](https://www.terraform.io/docs/language/modules/develop/structure.html).

## Testing and linting

Code is linted using `terraform fmt`.

Code is tested using [Kitchen Terraform](https://github.com/newcontext-oss/kitchen-terraform) to build example infrastructure in AWS and then run integration tests against it. You can run these tests locally be installing dependencies (Ruby 2.7 (ruby devel needed as well) installed and bundler, then you can run `bundle install` in the repos home directory), or **alternatively** you can use the [Docker image](https://github.com/dwp/github-action-kitchen-terraform) used by the pipeline. For convenience, the following have been added to the [Makefile](Makefile):
- `test                            `:  Build, test, and destroy default scenario with Kitchen Terraform
- `test-hybrid-external-database   `:  Build, test, and destroy hybrid-external-database scenario with Kitchen Terraform
- `build                           `:  Build default scenario with Kitchen Terraform
- `build-hybrid-external-database  `:  Test hybrid-external-database scenario with Kitchen Terraform
- `destroy                         `:  Build default scenario with Kitchen Terraform
- `destroy-hybrid-external-database`:  Test hybrid-external-database scenario with Kitchen Terraform

:warning: Running the integration tests will incur costs in your AWS account

### PR Pipeline

The [GitHub Actions pipeline](.github/workflows/pr.yml) runs the integration tests against an AWS account owned by the repo maintainer. The credentials for doing this are kept in a deactivated state and first need to be enabled by an administrator. As such the flow is typically:
1. Raise pull request
1. Pipeline fails on `PR / Test AWS Credentials (pull_request)`
1. A maintainer reviews the code
1. A maintainer then activates/enables the pipelines credentials in AWS (if PR changes pass initial review)
1. A maintainer then re-runs the pipeline, which deactivates the credentials when complete


## Updating Changelog

If you open a GitHub pull request on this repo, please update `CHANGELOG` to reflect your contribution.

Add your entry under `Unreleased` as `Breaking changes`, `New features`, `Fixes`.

Internal changes to the project that are not part of the public API do not need changelog entries, for example fixing the CI build server.

These sections follow [semantic versioning](https://semver.org/), where:

- `Breaking changes` corresponds to a `major` (1.X.X) change.
- `New features` corresponds to a `minor` (X.1.X) change.
- `Fixes` corresponds to a `patch` (X.X.1) change.

See the [`CHANGELOG_TEMPLATE.md`](CHANGELOG_TEMPLATE.md) for an example for how this looks.


## Releasing a new version

Each merge to `main` branch will create a GitHub release using semver 1.2.3 syntax. Each GitHub release will also be presented as a version on [Terraform Registry](https://registry.terraform.io/modules/dwp/kong-gateway/aws).
