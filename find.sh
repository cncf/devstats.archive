#!/bin/bash
if [ -z "$1" ]
then
  echo "You need to provide path as first arument"
  exit 1
fi
if [ -z "$2" ]
then
  echo "You need to provide file name pattern as a first argument"
  exit 1
fi
if [ -z "$3" ]
then
  echo "You need to provide regexp pattern to search for as a second argument"
  exit 1
fi
find "$1" -type f -iname "$2" -not -name "out" -not -path '*.git/*' -exec grep -EHIn "$3" "{}" \; | tee -a out
