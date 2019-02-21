#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: required db name"
  exit 1
fi
echo 'This script is deprecated, please use ./devel/gen_structure_sql.sh instead.'
./devel/db.sh pg_dump -s "$1" > structure.sql
