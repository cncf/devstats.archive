#!/bin/bash
# This dry-runs all manifests given, doing environment subsititution and setting TIMESTAMP to the current time with microsecond resolution
if [ -z "${AWS_PROFILE}" ]
then
  echo "$0: you need to set AWS_PROFILE=... to run this script"
  exit 1
fi
export TIMESTAMP=`date +'%s%N'`
for f in "$@"
do
  echo "Applying '$f'"
  rm -f error.yaml
  cat "$f" | envsubst
  cat "$f" | envsubst | kubectl apply --dry-run -f - || cat "$f" | envsubst > error.yaml
  if [ -f "error.yaml" ]
  then
    echo "$0: cannot apply $f, please examine error.yaml file"
    exit 1
  fi
done
