#!/bin/bash
# SKIPTEMP=1 skip regenerating data into temporary database and use current database directly
# SKIP_IMP_AFFS=percent - % chance to skip import_affs.sh phase
# SKIP_UPD_AFFS=percent - % chance to skip update_affs.sh phase
if ( [ -z "$GHA2DB_PROJECT" ] || [ -z "$PG_DB" ] || [ -z "$PG_PASS" ] )
then
  echo "$0: you need to set GHA2DB_PROJECT, PG_DB, PG_PASS env variables to use this script"
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

if [ ! -z "$SKIPTEMP" ]
then
  db=$PG_DB
  tdb=$PG_DB
else
  db=$PG_DB
  tdb="${PG_DB}_temp"
  ./devel/db.sh pg_dump -Fc $db -f /tmp/$tdb.dump || exit 1
  mv /tmp/$tdb.dump . || exit 2
  ./devel/restore_db.sh $tdb || exit 3
fi

if [ "$SKIP_IMP_AFFS" = "0" ]
then
  export SKIP_IMP_AFFS=''
fi
if [ ! -z "$SKIP_IMP_AFFS" ]
then
  rval=$(((RANDOM%100)+1))
  if [ "$rval" -gt "$SKIP_IMP_AFFS" ]
  then
    echo "Random value: $rval > $SKIP_IMP_AFFS, skipping importing affiliations"
    export SKIP_IMP_AFFS=1
  else
    echo "Random value: $rval <= $SKIP_IMP_AFFS, importing"
    export SKIP_IMP_AFFS=''
  fi
fi

if [ "$SKIP_UPD_AFFS" = "0" ]
then
  export SKIP_UPD_AFFS=''
fi
if [ ! -z "$SKIP_UPD_AFFS" ]
then
  rval=$(((RANDOM%100)+1))
  if [ "$rval" -gt "$SKIP_UPD_AFFS" ]
  then
    echo "Random value: $rval > $SKIP_UPD_AFFS, skipping TSDB regenerate (company related)"
    export SKIP_UPD_AFFS=1
  else
    echo "Random value: $rval <= $SKIP_UPD_AFFS, performing TSDB regenerate (company related)"
    export SKIP_UPD_AFFS=''
  fi
fi

proj=$GHA2DB_PROJECT
if [ -z "$SKIP_IMP_AFFS" ]
then
  if [ -f "./$proj/import_affs.sh" ]
  then
    PG_DB=$tdb ./$proj/import_affs.sh || exit 4
  else
    GHA2DB_PROJECT=$proj PG_DB=$tdb ./shared/import_affs.sh || exit 5
  fi
fi

if [ -z "$SKIP_UPD_AFFS" ]
then
  if [ -f "./$proj/update_affs.sh" ]
  then
    PG_DB=$tdb ./$proj/update_affs.sh || exit 6
  else
    GHA2DB_PROJECT=$proj PG_DB=$tdb ./shared/update_affs.sh || exit 7
  fi
fi

if [ -z "$SKIPTEMP" ]
then
  ./devel/drop_psql_db.sh $db || exit 8
  ./devel/db.sh psql postgres -c "select pg_terminate_backend(pid) from pg_stat_activity where datname = '$tdb'" || exit 9
  ./devel/db.sh psql postgres -c "alter database \"$tdb\" rename to \"$db\"" || exit 10
  rm -f $tdb.dump || exit 11
fi
