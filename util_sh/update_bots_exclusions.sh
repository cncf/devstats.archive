#!/bin/bash
for f in `find . -iname "*.sql"`
do
  grep -HIn "exclude_bots" "$f" 1>/dev/null 2>/dev/null
  if [ "$?" = "0" ]
  then
    echo $f
    MODE=rr FROM='\((.*)\s+{{exclude_bots}}\)' TO='(lower($1) {{exclude_bots}})' ./replacer $f || exit 1
  fi
done
