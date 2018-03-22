#!/bin/bash
if [ -z "$1" ]
then
  echo "Argument required: repo path"
  exit 1
fi

cd "$1" || exit 3
git tag -l --format="%(refname:short)♂♀%(creatordate:unix)♂♀%(subject)"
