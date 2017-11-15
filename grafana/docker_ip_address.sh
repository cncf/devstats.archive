#!/bin/sh
if [ -z "$1" ]
then
  echo "You need to provide docker conatiner name as agrument"
  docker ps
  exit 1
fi
docker inspect $1 | grep 'IPAddress'
