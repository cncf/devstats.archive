#!/bin/bash
# SKIPDEL=1 - skip delete current vars
if [ -z "$1" ]
then
  echo "$0: you need to specify file name as an argument (SQLite SQL file)"
  exit 1
fi
. ./devel/all_projs.sh || exit 2
for proj in $all
do
    db=$proj
    if [ "$proj" = "kubernetes" ]
    then
      db="k8s"
    fi
    echo "Project: $proj, PDB: $db"
    sqlite3 "/var/lib/grafana.$db/grafana.db" < "$1"
done
echo 'OK'
