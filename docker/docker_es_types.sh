#!/bin/bash
if [ -z "${ES_URL}" ]
then
  ES_URL="http://localhost:19200"
fi
if [ -z "$1" ]
then
  echo "$0: please provide index name as an argument"
  exit 1
fi
curl -XGET "${ES_URL}/${1}/_mapping?pretty"
