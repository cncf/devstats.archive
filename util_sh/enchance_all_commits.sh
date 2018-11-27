#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
if [ -z "${FROM}" ]
then
  echo "You need to set FROM=YYYY-MM-DD environment variable to run this script"
  exit 2
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
  GHA2DB_GHAPISKIPEVENTS=1 GHA2DB_RECENT_REPOS_RANGE="5 years" GHA2DB_PROJECT="$proj" PG_DB="$db" ./ghapi2db
done

echo 'OK'
