#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: you need to provide a JSON file to do the update"
  exit 1
fi
curr_h=`cat "$1" | jq '.panels[] | select(.title == "Dashboard documentation") | .gridPos.h' 2>/dev/null` || { echo "$1: property not found" ; exit 0; }
if [ -z "$curr_h" ]
then
  exit 0
fi
scaled=`echo "$curr_h*1.2" | bc`
scaled=`printf "%.0f\n" $scaled`
jq "(.panels[] | select(.title == \"Dashboard documentation\") | .gridPos.h) |= $scaled" "$1" > out && mv out "$1" && echo "$1 $curr_h -> $scaled"
