#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: need database name argument"
  exit 1
fi
proj=$1
tables=`./devel/db.sh psql $proj -qAntc '\dt' | cut -d\| -f2`
for table in $tables
do
  base=${table:0:1}
  if ( [ "$base" = "t" ] || [ "$base" = "s" ] )
  then
    ./devel/db.sh psql $proj -c "drop table \"$table\"" || exit 1
    echo "dropped $table"
  fi
done
