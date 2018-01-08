#!/bin/sh
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

cd "$1" || exit 2
git diff-tree --no-commit-id --name-only -r "$2" || exit 3
