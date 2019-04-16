#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+knative,+linux,+zephyr" ./devel/all_affs.sh || exit 2
GHA2DB_RECENT_RANGE="12 hours" GHA2DB_TMOFFSET="-4" GHA2DB_PROJECTS_OVERRIDE="+cncf,+opencontainers,+istio,+knative,+linux,+zephyr" devstats
