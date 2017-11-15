#!/bin/sh
if [ -z "$1" ]
then
  echo "You need to provide database name as argument"
  exit 1
fi
if [ -z "${IDB_PASS}" ]
then
  echo "You need to set IDB_PASS environment variable to run this script"
  exit 1
fi
if [ -z "${IDB_HOST}" ]
then
  echo "You need to set IDB_HOST environment variable to run this script"
  exit 1
fi
echo "Recreate InfluxDB $1"
echo "drop database $1" | influx -host "${IDB_HOST}" -username gha_admin -password "$IDB_PASS" || exit 1
echo "create database $1" | influx -host "${IDB_HOST}" -username gha_admin -password "$IDB_PASS" || exit 1
echo "grant all privileges on $1 to gha_admin" | influx -host "${IDB_HOST}" -username gha_admin -password "$IDB_PASS" || exit 1
echo "$1: all OK" && exit 0
