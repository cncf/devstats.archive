#!/bin/sh
if [ -z "$1" ]
then
  echo "Argument required: path to call git-reset and the git-pull"
  exit 1
fi

cd "$1" || exit 1
git reset --hard || exit 2
git pull || exit 3
