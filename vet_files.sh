#!/bin/bash
$1 *.go || exit 1
for dir in `find ./cmd/ -mindepth 1 -type d`
do
  $1 $dir/*.go || exit 1
done
exit 0
