#!/bin/sh
for f in `find . -type f -iname "*.go"`
do
	go vet "$f" || exit 1
done
exit 0
