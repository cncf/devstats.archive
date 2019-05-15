#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: need to specify server url as an argument"
  exit 1
fi
wget -qO- "https://${1}/public/img/grafana_icon.svg" | grep svg
