#!/bin/bash
if [ -z "$AWS_PROFILE" ]
then
  echo "$0: you need to set AWS_PROFILE=..."
  exit 1
fi
helm install ./devstats-helm --set skipSecrets=1,skipPV=1,skipBootstrap=1,skipCrons=1,skipGrafanas=1,skipServices=1,indexProvisionsFrom=24,indexProvisionsTo=25,provisionCommand='./k8s/affs.sh'
