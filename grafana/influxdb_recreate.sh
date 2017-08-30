#!/bin/sh
echo "Recreate InfluxDB"
echo "drop database gha" | influx || exit 1
echo "create database gha" | influx || exit 1
echo "grant all privileges on gha to gha_admin" | influx || exit 1
echo "All OK" && exit 0
