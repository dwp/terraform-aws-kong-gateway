DEFAULT_KITCHEN_TERRAFORM_TAG=2.0.1

# Parse parameters
while [[ "$#" > 0 ]]; do case $1 in
  --tag) TAG="$2"; shift; shift;;
  --aws-profile) AWS_PROFILE="$2"; shift; shift;;
  --action) ACTION="$2"; shift; shift;;
  --args) ARGS="$2"; shift; shift;;
  *) usage "Unknown parameter passed: $1"; shift; shift;;
esac; done

# Default version of Terraform when not specified a tag
TAG="${TAG:-$DEFAULT_KITCHEN_TERRAFORM_TAG}"
IMAGE="quay.io/dwp/kitchen-terraform:${TAG}"

# Default AWS Profile
AWS_PROFILE="${AWS_PROFILE:-"default"}"

printf "\n*************************************************************\n"
printf "  Running Kitchen Terraform using the following parameters:\n"
printf "  %-22s %s\n" "- Terraform version:" $TAG
printf "  %-22s %s\n" "- AWS Profile:" $AWS_PROFILE
printf "  %-22s %s\n" "- Kitchen action:" ${ACTION:-"(not set)"}
printf "  %-22s %s\n" "- Kitchen arguments:" ${ARGS:-"(not set)"}
printf "*************************************************************\n\n"

if [[ -n "$ACTION" ]]; then

  if [[ ${ACTION} == "debug" ]]; then
    docker run -ti --rm \
      --env AWS_PROFILE=$AWS_PROFILE \
      --env CUSTOM_CA_DIR=/usr/share/ca-certificates/custom \
      --volume /etc/ssl/certs/:/usr/share/ca-certificates/custom \
      --volume $(pwd):/usr/action \
      --volume ~/.aws:/root/.aws \
      --user root \
      --workdir /usr/action/ \
      --entrypoint bash \
      ${IMAGE}
  else
    docker run --rm \
      --env AWS_PROFILE=$AWS_PROFILE \
      $(if [[ ${ARGS} == *"ecs"* && -n ${KONG_EE_LICENSE} && ${ACTION} == "verify" || ${ACTION} == "test" ]]; then echo "--env KONG_EE_LICENSE=${KONG_EE_LICENSE}"; fi) \
      --env CUSTOM_CA_DIR=/usr/share/ca-certificates/custom \
      --volume /etc/ssl/certs/:/usr/share/ca-certificates/custom \
      --volume $(pwd):/usr/action \
      --volume ~/.aws:/root/.aws \
      --user root \
      --workdir /usr/action/ \
      ${IMAGE} "${ACTION}  ${ARGS}"
  fi

else
  echo "The following arguments are required: \`--action\`."
fi
