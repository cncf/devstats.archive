#!/bin/sh
# CALL this script with IDB_PASS='pwd_here' ./influxdb_setup.sh
echo "Initialize InfluxDB $1"
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
echo "create database $1" | influx || exit 1
echo "create user gha_admin with password '${IDB_PASS}' with all privileges" | influx || exit 1
echo "grant all privileges on $1 to gha_admin" | influx || exit 1
echo "show users" | influx || exit 1
echo "$1: all OK" && exit 0
