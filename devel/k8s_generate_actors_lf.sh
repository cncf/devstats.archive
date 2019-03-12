#!/bin/bash
if [ -z "${AWS_PROFILE}" ]
then
  echo "$0: you need to set AWS_PROFILE=... to run this script"
  exit 1
fi
if ( [ -z "${PG_PASS}" ] || [ -z "${PG_HOS}T" ] )
then
  echo "$0: you need to set PG_HOST=... and PG_PASS=... to run this script"
  exit 1
fi
ts=`date +'%s%N'`
kubectl run --env="PG_HOST=${PG_HOST}" --env="PG_PASS=${PG_PASS}" -i --tty "devstats-actors-${ts}" --restart=Never --rm --image="lukaszgryglicki/devstats" --command "./devel/generate_actors_lf.sh"
