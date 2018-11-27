#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: need table name prefix argument"
  exit 1
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
  echo "DB: $db, tables $1..."
  ./util_sh/drop_tables_by_name.sh "${db}" "$1"
done
