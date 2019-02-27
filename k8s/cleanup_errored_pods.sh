#!/bin/bash
if [ -z "${AWS_PROFILE}" ]
then
  echo "$0: you need to set AWS_PROFILE=... to run this script"
  exit 1
fi
pods=""
for data in `kubectl get po -l name=devstats -o=jsonpath='{range .items[*]}{.metadata.name}{";"}{.status.phase}{"\n"}{end}'`
do
  IFS=';'
  arr=($data)
  unset IFS
  pod=${arr[0]}
  sts=${arr[1]}
  base=${pod:0:8}
  # echo "$data -> $pod $sts $base"
  if ( [ "$sts" = "Failed" ] && [ "$base" = "devstats" ] )
  then
    pods="${pods} ${pod}"
  fi
done
if [ ! -z "$pods" ]
then
  echo "Deleting pods: ${pods}"
  kubectl delete pod ${pods}
fi
