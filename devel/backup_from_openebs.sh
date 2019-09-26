#!/bin/bash
export TEST_SERVER=1
. ./devel/all_dbs.sh || exit 1
# found=`find /var/www/html -iname "*.tar.xz"` || exit 2
found=`find /var/openebs/local -iname "*.tar.xz"` || exit 2
mkdir ~/backups 1>/dev/null 2>/dev/null
for db in $all
do
  db="$db.tar.xz"
  hit=''
  for f in $found
  do
    fa=(${f//\// })
    f2=${fa[-1]}
    if [ "$db" = "$f2" ]
    then
      hit="$f"
      break
    fi
  done
  if [ -z "$hit" ]
  then
    echo "$db backup not found"
  else
    echo "copying $f"
    cp "$f" ~/backups/ || exit 3
  fi
done
