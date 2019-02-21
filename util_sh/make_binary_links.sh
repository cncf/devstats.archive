#!/bin/bash
for f in "$@"
do
  echo $f
  ln -s "${GOPATH}/bin/${f}" "./${f}"
done
