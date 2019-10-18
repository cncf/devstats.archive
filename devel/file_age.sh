#!/bin/bash
if [ -z "$1" ]
then
  echo "no"
  exit 0
fi
if [ ! -f "$1" ]
then
  echo "no"
  exit 0
fi
fa=`date -r "$1" +%s`
fn=`date +%s`
a=$((fn-fa))
echo $a
