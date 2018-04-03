#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: need filename"
  exit 1
fi
cp metrics/nats/$1 tmp || exit 2
if [ -z "$ONLY" ]
then
  host=`hostname`
  if [ $host = "cncftest.io" ]
  then
    all=`cat ./devel/all_test_projects.txt`
  else
    all=`cat ./devel/all_prod_projects.txt`
  fi
else
  all=$ONLY
fi

for proj in $all
do
  if [ ! "$proj" = "kubernetes" ]
  then
    rm -f "metrics/$proj/$1" || exit 3
  fi
done
cp tmp metrics/shared/$1 || exit 4
