#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: filename.db"
  exit 1
fi
fn=`echo "$1" | cut -f1 -d'.'`
sqlite3 $fn.db ".output ${fn}.sql" '.dump' || exit 1
