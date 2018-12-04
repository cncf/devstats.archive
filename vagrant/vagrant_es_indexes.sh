#!/bin/bash
if [ -z "${ES_URL}" ]
then
  ES_URL="http://elasticsearch:9200"
fi
docker run --network=lfda_default devstats curl -XGET "${ES_URL}/_cat/indices?v"
