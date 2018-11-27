#!/bin/bash
if [ -z "${ES_URL}" ]
then
  ES_URL="http://localhost:19200"
fi
./docker/docker_es_indexes.sh 1>/dev/null 2>/dev/null && exit 0
while true
do
  ./docker/docker_es_indexes.sh 1>/dev/null 2>/dev/null
  r=$?
  if [ ! "$r" = "0" ]
  then
    echo "ES not ready: $r"
    sleep 1
  else
    break
  fi
done
echo "Was waiting for the ES, now ready"
