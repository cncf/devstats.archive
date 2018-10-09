#!/bin/bash
if [ -z "$1" ]
then
  echo "Argument required: path to call git-reset and the git-pull"
  exit 1
fi

cd "$1" || exit 2
git fetch origin || exit 3
git reset --hard origin/master || exit 4
git pull || exit 5
