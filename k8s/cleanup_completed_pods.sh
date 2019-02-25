#!/bin/bash
if [ -z "${AWS_PROFILE}" ]
then
  echo "$0: you need to set AWS_PROFILE=... to run this script"
  exit 1
fi
for data in `kubectl get po -o=jsonpath='{range .items[*]}{.metadata.name}{";"}{.status.phase}{"\n"}{end}'`
do
  IFS=';'
  arr=($data)
  unset IFS
  pod=${arr[0]}
  status=${arr[1]}
  # echo "$data -> $pod $status"
  if [ "$status" = "Succeeded" ]
  then
    kubectl delete pod "$pod"
  fi
done
