#!/bin/bash
logdb=devstats
logtable=gha_logs
waits=1
waitn=1
maxwait=9
if [ -z "$1" ]
then
  waitafter=5
else
  waitafter=$1
fi
while true
do
  exists=`./devel/db.sh psql -tAc "select 1" 2>&1`
  # echo "exists: '$exists'"
  if [[ "$exists" == *"you need to set PG_PASS"* ]]
  then
    echo "$0: no PG_PASS passed"
    exit 1
  fi
  if [[ "$exists" == *"could not translate host name"* ]]
  then
    echo "$0: #$waitn wait ${waits}s"
    sleep $waits
    if [ "$waitn" = "$maxwait" ]
    then
      echo "$0: aborting"
      echo "exists: '$exists'"
      exit 2
    fi
    ((waits*=2))
    ((waitn++))
    continue
  fi
  break
done
echo "Postgres available, waiting final ${waitafter}s"
sleep $waitafter
