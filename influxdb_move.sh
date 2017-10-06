#!/bin/sh
if [ -z "$1" ]
then
  echo "You need to provide input database name"
  exit 1
fi
if [ -z "$2" ]
then
  echo "You need to provide output database name"
  exit 1
fi
echo "drop database $2" | influx
echo "create database $2" | influx
echo "select * into $2..:MEASUREMENT FROM /.*/ GROUP BY *" | influx -database "$1"
