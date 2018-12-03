#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: need user name argument"
  exit 1
fi
if [ -z "$2" ]
then
  echo "$0: need database name argument"
  exit 1
fi
proj=$2
./devel/db.sh psql postgres -c "grant connect on database \"$proj\" to \"$1\"" || exit 1
./devel/db.sh psql postgres -c "grant usage on schema \"public\" to \"$1\"" || exit 1
tables=`./devel/db.sh psql $proj -qAntc '\dt' | cut -d\| -f2`
for table in $tables
do
  echo -n "$proj: $table "
  ./devel/db.sh psql $proj -c "grant select on $table to \"$1\"" || exit 1
done
