#!/bin/bash
# Call this script with IDB_PASS='pwd_here' IDB_PASS_RO='pwd_ro_here' IDB_HOST='host' ./influxdb_setup.sh
# This should be called before enabling authenticating via `[http] auth-enabled = true` in the config file.
echo "Initialize InfluxDB"
if [ -z "${IDB_PASS}" ]
then
  echo "You need to set IDB_PASS environment variable to run this script"
  exit 1
fi
if [ -z "${IDB_PASS_RO}" ]
then
  echo "You need to set IDB_PASS_RO environment variable to run this script"
  exit 1
fi
if [ -z "${IDB_HOST}" ]
then
  echo "You need to set IDB_HOST environment variable to run this script"
  exit 1
fi
echo "create user gha_admin with password '${IDB_PASS}' with all privileges" | influx -host "${IDB_HOST}" || exit 1
echo "create user ro_user with password '${IDB_PASS_RO}'" | influx -host "${IDB_HOST}" || exit 1
echo "show users" | influx -host "${IDB_HOST}" || exit 1
echo "All OK" && exit 0
