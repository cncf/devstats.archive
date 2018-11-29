#!/bin/bash
./docker/docker_es_indexes.sh 2>/dev/null 1>out || exit 1
cat out | grep '"status" : 404' && exit 2
cat out
export TEST_SERVER=1
export LIST_FN_PREFIX="docker/all_"
. ./devel/all_dbs.sh || exit 3
for db in $all
do
  idx="d_${db}"
  idx_raw="d_raw_${db}"
  echo "ES indexes: ${idx}, ${idx_raw}"
  ./docker/docker_es_types.sh "${idx}" 2>/dev/null 1>out || exit 4
  cat out | grep '"status" : 404' && exit 2
  ./docker/docker_es_types.sh "${idx_raw}" 2>/dev/null 1>out || exit 6
  cat out | grep '"status" : 404' && exit 2
  ./docker/docker_es_values.sh "${idx}" _doc 2>/dev/null 1>out || exit 8
  cat out | grep '"status" : 404' && exit 2
  ./docker/docker_es_values.sh "${idx_raw}" _doc 2>/dev/null 1>out || exit 10
  cat out | grep '"status" : 404' && exit 2
  ./docker/docker_es_query.sh "${idx_raw}" _doc 'type:text' 2>/dev/null 1>out || exit 12
  cat out | grep '"status" : 404' && exit 2
  ./docker/docker_es_query.sh "${idx}" _doc 'type:tvars AND vname:companies_summary_docs_html' 2>/dev/null 1>out || exit 14
  cat out | grep '"status" : 404' && exit 2
  #./docker/docker_es_query.sh "${idx_raw}" _doc 'type:text'
  #./docker/docker_es_query.sh "${idx}" _doc 'type:tvars AND vname:companies_summary_docs_html'
done
echo 'OK'
