#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
if [ -z "$1" ]
then
  echo "$0: you need to provide periods to calculate: 'w:f,m:f,q:f,y:f,a_33_34:t'"
  exit 1
fi

function finish {
    sync_unlock.sh
    rm -f /tmp/deploy.wip 2>/dev/null
}
if [ -z "$TRAP" ]
then
  sync_lock.sh || exit -1
  trap finish EXIT
  export TRAP=1
  > /tmp/deploy.wip
fi

. ./devel/all_projs.sh || exit 2
for proj in $all
do
  db=$proj
  if [ "$proj" = "kubernetes" ]
  then
    db="gha"
  elif [ "$proj" = "all" ]
  then
    db="allprj"
  fi
  GHA2DB_PROJECT=$proj PG_DB=$db ./util_sh/recalculate_periods.sh "$1" || exit 3
done
echo 'OK'
