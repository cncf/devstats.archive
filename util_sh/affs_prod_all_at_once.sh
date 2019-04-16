#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
./devel/all_affs.sh || exit 2
GHA2DB_RECENT_RANGE="8 hours" GHA2DB_TMOFFSET="-4" devstats
./devel/columns_all.sh
