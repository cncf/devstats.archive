#!/bin/bash
if [ -z "${ES_URL}" ]
then
  ES_URL="http://localhost:19200"
fi
if [ -z "$1" ]
then
  echo "$0: please provide index name as a first argument"
  exit 1
fi
if [ -z "$2" ]
then
  echo "$0: please provide type name as a second argument"
  exit 2
fi
curl -XGET "${ES_URL}/${1}/${2}/_search?pretty"
