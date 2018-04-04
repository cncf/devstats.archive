#!/bin/bash
for f in `find . -name "*.was"`
do
    f2=${f%.*}
    mv "$f" "$f2" || exit 1
done
echo 'OK'
