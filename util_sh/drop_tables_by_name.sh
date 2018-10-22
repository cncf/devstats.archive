#!/bin/bash
if ( [ -z "$1" ] || [ -z "$2" ] )
then
  echo "$0: need database name argument and table name prefix argument"
  exit 1
fi
proj=$1
len=${#2}
tables=`sudo -u postgres psql $proj -qAntc '\dt' | cut -d\| -f2`
for table in $tables
do
  base=${table:0:$len}
  if [ "$base" = "$2" ]
  then
    sudo -u postgres psql $proj -c "drop table \"$table\"" || exit 1
    echo "dropped $table"
  fi
done
