#!/bin/bash
# This applies all manifests giveni, doing environment subsititution, setting TIMESTAMP to the current time with microsecond resolution and replacing pod command with bash shell
# So you can use ./k8s/pod_shell.sh to get a pod shell and execute its command manually
if [ -z "$1" ]
then
  echo "$0: required mainfiest file"
  exit 1
fi
export TIMESTAMP=`date +'%s%N'`
cat "$1" | envsubst | kubectl create -f -
