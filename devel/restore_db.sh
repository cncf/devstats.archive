#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: you need to provide database name"
  exit 1
fi
sudo -u postgres dropdb $1
sudo -u postgres createdb $1
sudo -u postgres pg_restore -d $1 $1.dump
