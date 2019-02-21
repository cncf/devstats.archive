#!/bin/bash
for f in "$@"
do
  echo $f
  ln -s "/usr/bin/${f}" "./${f}"
done
