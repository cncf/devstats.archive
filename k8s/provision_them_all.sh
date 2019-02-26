#!/bin/bash
if [ -z "${AWS_PROFILE}" ]
then
  echo "$0: you need to set AWS_PROFILE=... to run this script"
  exit 1
fi
ret=`PROJ=iovisor PROJDB=iovisor PROJREPO='iovisor/bcc' INIT=1 ONLYINIT=1 ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml`
st=$?
if [ ! "$st" = "0" ]
then
  echo "Init status non-zero: $st"
  exit 1
fi
arr=($ret)
ret=${arr[0]}
IFS='/'
arr=($ret)
unset IFS
pod=${arr[1]}
echo "Waiting for pod: $pod"
while true
do
  st=`kubectl get po devstats-provision-1551164749915048362 -o=jsonpath='{.status.phase}'`
  # echo "status: $st"
  if [ "$st" = "Succeeded" ]
  then
    break
  fi
  if ( [ "$st" = "Failed" ] || [ "$st" = "CrashLoopBackOff" ] )
  then
    echo "Exiting due to pod status: $st"
    exit 1
  fi
  sleep 1
done
echo "Initial setup (blocking) complete, now spawn N provision pods in parallel"
ret=`PROJ=iovisor PROJDB=iovisor PROJREPO='iovisor/bcc' INIT=1 ONLYINIT=1 ./k8s/apply_manifest.sh ./k8s/manifests/devstats-provision.yaml`
st=$?
