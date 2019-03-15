#!/bin/bash
if [ -z "${AWS_PROFILE}" ]
then
  echo "$0: you need to set AWS_PROFILE=... to run this script"
  exit 1
fi
if [ -z "$1" ]
then
  echo "$0: you need to provide profile name as an argument, use 'default' to switch to the default profile"
  exit 1
fi

export AWS_PROFILE

kubectl config set-context $(kubectl config current-context) --namespace=$1
