#!/bin/bash
if [ -z "${AWS_PROFILE}" ]
then
  echo "$0: you need to set AWS_PROFILE=... to run this script"
  exit 1
fi
if [ -z "$1" ]
then
  echo "$0: you need to pass  pod name as an argument"
  exit 2
fi
kubectl exec -it "$1" -- /bin/bash
