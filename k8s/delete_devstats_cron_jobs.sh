#!/bin/bash
if [ -z "${AWS_PROFILE}" ]
then
  echo "$0: you need to set AWS_PROFILE=... to run this script"
  exit 1
fi
cjobs=""
for job in `kubectl get cronjobs -o=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'`
do
  base=${job:0:8}
  echo "$base"
  if [ "$base" = "devstats" ]
  then
    cjobs="${cjobs} ${job}"
  fi
done
if [ ! -z "$cjobs" ]
then
  echo "Deleting cronjobs: ${cjobs}"
  kubectl delete cronjob ${cjobs}
fi
