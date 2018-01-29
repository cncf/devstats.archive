#!/bin/sh
if [ -z "$1" ]
then
  echo "You need to provide file name pattern as a first argument"
  exit 1
fi
if [ -z "$2" ]
then
  echo "You need to provide regexp pattern to search for as a second argument"
  exit 1
fi
find . -iname "$1" -exec grep -EHIn "$2" "{}" \; | tee -a out
