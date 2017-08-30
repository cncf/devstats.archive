#!/bin/sh
# CALL this script with IDB_PASS='pwd_here' ./influxdb_setup.sh
echo "Initialize InfluxDB"
if [ -z "${IDB_PASS}" ]
then
  echo "You need to set IDB_PASS environment variable to run this script"
  exit 1
fi
echo "create database gha" | influx || exit 1
echo "create user gha_admin with password '${IDB_PASS}' with all privileges" | influx || exit 1
echo "grant all privileges on gha to gha_admin" | influx || exit 1
echo "show users" | influx || exit 1
echo "All OK" && exit 0
