#!/bin/bash
if [ -z "$1" ]
then
  echo "Usage $0 on|off"
  exit 1
fi

crontab -l > /tmp/crontab.tmp
if [ "$1" = "off" ]
then
  MODE=rr0 FROM='(?m)^([^#].*\s+devstats\s+.*)$' TO='#$1' replacer /tmp/crontab.tmp
elif [ "$1" = "on" ]
then
  MODE=rr0 FROM='(?m)^#(.*\s+devstats\s+.*)$' TO='$1' replacer /tmp/crontab.tmp
else
  echo "Usage $0 on|off"
  rm -f /tmp/crontab.tmp
  exit 1
fi
crontab /tmp/crontab.tmp
rm -f /tmp/crontab.tmp
