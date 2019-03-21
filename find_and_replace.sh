#!/bin/bash
if [ -z "$FROM" ]
then
  export FROM="`cat ./FROM`"
fi
if [ -z "$TO" ]
then
  export TO="`cat ./TO`"
fi
if [ -z "$MODE" ]
then
  export MODE=ss0
fi
if [ -z "$FILES" ]
then
  if [ -z "$1" ]
  then
    echo "You need to provide path as first arument"
    exit 1
  fi
  if [ -z "$2" ]
  then
    echo "You need to provide file name pattern as a second argument"
    exit 2
  fi
  if [ -z "$3" ]
  then
    echo "You need to provide regexp pattern to search for as a third argument"
    exit 3
  fi
  find "$1" -type f -iname "$2" -not -name "out" -not -path '*.git/*' -exec grep -El "$3" "{}" \; > out
  export FILES=`cat out`
fi
if [ -z "$DRY" ]
then
  ./devel/mass_replace.sh
else
  echo "from: '$FROM'"
  echo "to: '$TO'"
  echo "mode: '$MODE'"
  echo "files: '$FILES'"
fi
