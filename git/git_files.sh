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
git show -s --format=%ct "$2" || exit 4
#files=`git diff-tree --no-commit-id --name-only -M8 -m -r "$2"` || exit 5
#files=`git diff-tree --no-commit-id --name-only -r "$2"` || exit 5
files=`git diff-tree --no-commit-id --name-only -M7 -r "$2"` || exit 5
for file in $files
do
    file_and_size=`git ls-tree -r -l "$2" "$file" | awk '{print $5 "♂♀" $4}'`
    if [ -z "$file_and_size" ]
    then
      echo "$file♂♀-1"
    else
      echo "$file_and_size"
    fi
done
