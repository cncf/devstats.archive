#!/bin/sh
if [ -z "$1" ]
then
  echo "You need to provide database name as argument"
  exit 1
fi
echo "Recreate InfluxDB $1"
echo "drop database $1" | influx || exit 1
echo "create database $1" | influx || exit 1
echo "grant all privileges on $1 to gha_admin" | influx || exit 1
echo "$1: all OK" && exit 0
