#!/bin/bash
for f in `find . -iname *.png`
do
  optipng -o7 "${f}" && ls -l "$f"
done
