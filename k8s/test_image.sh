#!/bin/bash
if [ -z "${AWS_PROFILE}" ]
then
  echo "$0: you need to set AWS_PROFILE=... to run this script"
  exit 1
fi
if [ -z "${DOCKER_USER}" ]
then
  echo "$0: you need to set docker user via DOCKER_USER=username"
  exit 2
fi
if [ -z "$1" ]
then
  echo "$0: you need to pass devstats image name as an agument, possible options are: devstats or devstats-minimal"
  echo "$0: if you've used docker/Dockerfile.minila instead of docker/Dockerfile.minimal.debug there will be no /bin/sh command to run"
  exit 3
fi
command="$2"
if [ -z "${command}" ]
then
  export command=/bin/bash
fi
kubectl run -i --tty "${1}-test" --restart=Never --rm --image="${DOCKER_USER}/$1" --command "$command"
