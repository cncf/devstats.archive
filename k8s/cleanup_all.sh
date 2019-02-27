#!/bin/bash
if [ -z "${AWS_PROFILE}" ]
then
  echo "$0: you need to set AWS_PROFILE=... to run this script"
  exit 1
fi
./k8s/cleanup_completed_pods.sh
./k8s/cleanup_errored_pods.sh
./k8s/delete_devstats_cron_jobs.sh

