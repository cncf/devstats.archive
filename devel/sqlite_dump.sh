#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: required Grafana DB name"
  exit 1
fi
sqlite3 /var/lib/grafana.$1/grafana.db .dump > grafana_$1.sql
