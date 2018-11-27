#!/bin/bash
# PG_PASS=... ONLY=kubernetes ./devel/sync_selected_metrics_from_all.sh 'events,activity_repo_groups' '2018-04-27'
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
if ( [ -z "$1" ] || [ -z "$2" ] )
then
  echo "$0: required comma separated list of metrics to run and start date"
  echo "Example: $0 'events,activity_repo_groups' '2018-04-28'"
  exit 1
fi

function finish {
    sync_unlock.sh
}
if [ -z "$TRAP" ]
then
  sync_lock.sh || exit -1
  trap finish EXIT
  export TRAP=1
fi

. ./devel/all_projs.sh || exit 2
for proj in $all
do
  db=$proj
  if [ "$db" = "kubernetes" ]
  then
    db="gha"
  elif [ "$db" = "all" ]
  then
    db="allprj"
  fi
  GHA2DB_PROJECT=$proj PG_DB=$db ./devel/sync_selected_metrics_from.sh $* || exit 2
done

echo 'OK'
