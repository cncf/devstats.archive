#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: please provide a file name as a 1st arg"
  exit 1
fi
cat "$1" | jq '.' -S > out && mv out "$1"
