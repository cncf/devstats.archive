#!/bin/sh
if [ -z "$AWS_PROFILE" ]
then
  echo "$0: you need to set AWS_PROFILE=..."
  exit 1
fi
./k8s/delete_devstats_cron_jobs.sh || exit 2
helm install ./devstats-helm --set skipSecrets=1,skipPV=1,skipBootstrap=1,skipProvisions=1,skipGrafanas=1,skipServices=1 || exit 3
echo 'OK'
