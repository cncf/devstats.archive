#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: need database name argument"
  exit 1
fi
if [ -z "$2" ]
then
  echo "$0: need table name prefix"
  exit 1
fi
proj=$1
plen=${#2}
tables=`sudo -u postgres psql $proj -qAntc '\dt' | cut -d\| -f2`
for table in $tables
do
  base=${table:0:$plen}
  if [ "$base" = "$2" ]
  then
    sudo -u postgres psql $proj -c "drop table \"$table\"" || exit 2
    echo "dropped $table"
  fi
done
