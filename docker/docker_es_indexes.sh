#!/bin/bash
if [ -z "${ES_URL}" ]
then
  ES_URL="localhost:19200"
fi
curl -XGET "${ES_URL}/_cat/indices?v"
