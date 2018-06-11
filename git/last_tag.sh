#!/bin/bash
if [ -z "$1" ]
then
  echo "Argument required: repo path"
  exit 1
fi

cd "$1" || exit 2
git describe --abbrev=0 --tags || echo "-"
