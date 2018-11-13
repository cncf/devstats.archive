#!/bin/bash
# NOLOCK=1 skip
if [ ! -z "$NOLOCK" ]
then
  exit 0
fi
set -o pipefail
if ([ -z "$1" ] || [ -z "$2" ])
then
  echo "Usage $0 command on|off"
  exit 1
fi
crontab -l > /tmp/crontab.tmp
if [ "$2" = "off" ]
then
  MODE=rr0 FROM="(?m)^([^#].*\s+$1\s+.*)$" TO='#$1' replacer /tmp/crontab.tmp > /dev/null || exit 1
elif [ "$2" = "on" ]
then
  MODE=rr0 FROM="(?m)^#(.*\s+$1\s+.*)$" TO='$1' replacer /tmp/crontab.tmp > /dev/null || exit 2
else
  echo "Usage $0 command on|off"
  rm -f /tmp/crontab.tmp
  exit 1
fi
crontab /tmp/crontab.tmp || exit 3
rm -f /tmp/crontab.tmp
