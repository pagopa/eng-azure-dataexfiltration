#!/bin/bash

set -e

action="$1"
env="$2"
all=("$@")
other=("${all[@]:2}")

if [[ -z "$action" ]]; then
    printf "%s\n" "terraform.sh: missing action"
    exit 1
fi

if [[ -z "$env" ]]; then
    printf "%s\n" "terraform.sh: missing environment"
    exit 1
fi

envs="dev / prod"
if ! printf "%s" "$envs" | grep -w "$env" > /dev/null; then
  printf "%s\n" "terraform.sh: env should be only $envs"
  exit 1
fi

# shellcheck source=/dev/null
source "./env/$env/backend.ini"

az account set -s "${subscription}"

echo "SUBSCRIPTION: ${subscription}"

if printf "%s" "init plan apply refresh import output state taint destroy console validate fmt" | grep -w "$action" > /dev/null; then
  if [[ "$action" = "init" ]]; then
    terraform "$action" -backend-config="./env/$env/backend.tfvars" "${other[@]}"
  elif [[ "$action" = "validate" ]]; then
    terraform "$action" "${other[@]}"
  elif [[ "$action" = "fmt" ]]; then
    terraform "$action" "${other[@]}"
  elif [[ "$action" = "output" ]] || [[ "$action" = "state" ]] || [[ "$action" = "taint" ]]; then
    # init terraform backend
    terraform init -reconfigure -backend-config="./env/$env/backend.tfvars"
    if ((${#other[@]})); then
        terraform "$action" "${other[@]}"
    else
        terraform "$action"
    fi
  else
    # init terraform backend
    terraform init -reconfigure -backend-config="./env/$env/backend.tfvars"
    if ((${#other[@]})); then
        terraform "$action" -var-file="./env/$env/terraform.tfvars" "${other[@]}"
    else
        terraform "$action" -var-file="./env/$env/terraform.tfvars"
    fi
  fi
else
    printf "%s\n" "terraform.sh: $action action not allowed"
    exit 1
fi
