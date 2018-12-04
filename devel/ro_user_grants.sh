#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: need database name argument"
  exit 1
fi
user=gha_admin
if [ ! -z "${PG_USER}" ]
then
  user="${PG_USER}"
fi
proj=$1
tables=`./devel/db.sh psql $proj -qAntc '\dt' | cut -d\| -f2`
for table in $tables
do
  echo -n "$proj: $table "
  PG_USER="${user}" ./devel/db.sh psql $proj -c "grant select on $table to ro_user" || exit 1
done
