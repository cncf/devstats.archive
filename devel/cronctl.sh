#!/bin/bash
set -o pipefail
if ([ -z "$1" ] || [ -z "$2" ])
then
  echo "Usage $0 command on|off"
  exit 1
fi
crontab -l > /tmp/crontab.tmp
if [ "$2" = "off" ]
then
  MODE=rr0 FROM="(?m)^([^#].*\s+$1\s+.*)$" TO='#$1' replacer /tmp/crontab.tmp
elif [ "$2" = "on" ]
then
  MODE=rr0 FROM="(?m)^#(.*\s+$1\s+.*)$" TO='$1' replacer /tmp/crontab.tmp
else
  echo "Usage $0 command on|off"
  rm -f /tmp/crontab.tmp
  exit 1
fi
crontab /tmp/crontab.tmp
rm -f /tmp/crontab.tmp
