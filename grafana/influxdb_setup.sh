#!/bin/sh
# CALL this script with INFLUXDB_PASS='pwd_here' ./influxdb_setup.sh
echo "Initialize InfluxDB"
if [ -z "${INFLUXDB_PASS}" ]
then
  echo "You need to set INFLUXDB_PASS environment variable to run this script"
  exit 1
fi
echo "create database gha" | influx || exit 1
echo "create user gha_admin with password '${INFLUXDB_PASS}' with all privileges" | influx || exit 1
echo "grant all privileges on gha to gha_admin" | influx || exit 1
echo "show users" | influx || exit 1
echo "All OK" && exit 0
