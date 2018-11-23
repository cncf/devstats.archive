#!/bin/bash
# NODATA=1 (skip dumping data)
# NOMETA=1 (skip dumping metadata)
if [ -z "${ES_URL}" ]
then
  ES_URL="http://localhost:19200"
fi
if [ -z "$1" ]
then
  echo "$0: please provide from index name as a first argument"
  exit 1
fi
if [ -z "$2" ]
then
  echo "$0: please provide output file name as a second argument (only root filename, like: git)"
  exit 2
fi
if [ -z "${NOMETA}" ]
then
  elasticdump --input "${ES_URL}/${1}" --output "${2}.alias.json" --type=alias
  elasticdump --input "${ES_URL}/${1}" --output "${2}.mapping.json" --type=mapping
  elasticdump --input "${ES_URL}/${1}" --output "${2}.settings.json" --type=settings
  elasticdump --input "${ES_URL}/${1}" --output "${2}.analyzer.json" --type=analyzer
fi
if [ -z "${NODATA}" ]
then
  elasticdump --input "${ES_URL}/${1}" --output "${2}.data.json" --type=data
fi
