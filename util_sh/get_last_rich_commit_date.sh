#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
if [ -z "$1" ]
then
  echo "You need to provide repo name as an argument"
  exit 2
fi
GHA2DB_LOCAL=1 GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 runq util_sql/get_last_rich_commit_date.sql {{repo}} "'$1'"
