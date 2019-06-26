#!/bin/bash
if [ -z "$1" ]
then
  echo "Arguments required: path sha, none given"
  exit 1
fi
if [ -z "$2" ]
then
  echo "Arguments required: path sha, only path given"
  exit 2
fi

cd "$1" || exit 3
output=`git show "$2" --shortstat --oneline`
if [ ! "$?" = "0" ]
then
  exit 4
fi
output=`echo "$output" | tail -1`
echo $output
