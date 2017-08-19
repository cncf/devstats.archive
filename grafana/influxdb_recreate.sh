#!/bin/sh
# CALL this script with INFLUXDB_PASS='pwd_here' ./influxdb_setup.sh
echo "Recreate InfluxDB"
if [ -z "${INFLUXDB_PASS}" ]
then
  echo "You need to set INFLUXDB_PASS environment variable to run this script"
  exit 1
fi
echo "drop database gha" | influx || exit 1
echo "create database gha" | influx || exit 1
echo "grant all privileges on gha to gha_admin" | influx || exit 1
echo "All OK" && exit 0
