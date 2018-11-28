#!/bin/bash
r=`./docker/docker_es_indexes.sh 2>/dev/null` || exit 1
echo "$r" | grep '"status" : 404' && exit 2
echo $r

. ./devel/all_dbs.sh || exit 3
for db in $all
do
  idx="d_${db}"
  idx_raw="d_raw_${db}"
  echo ": $db"
  r=`./docker/docker_es_types.sh "${idx}" 2>/dev/null` || exit 4
  echo "$r" | grep '"status" : 404' && exit 5
  echo $r
  r=`./docker/docker_es_types.sh "${idx_raw}" 2>/dev/null` || exit 6
  echo "$r" | grep '"status" : 404' && exit 7
  echo $r
  r=`./docker/docker_es_values.sh "${idx}" _doc 2>/dev/null` || exit 8
  echo "$r" | grep '"status" : 404' && exit 9
  echo $r
  r=`./docker/docker_es_values.sh "${idx_raw}" _doc 2>/dev/null` || exit 10
  echo "$r" | grep '"status" : 404' && exit 11
  echo $r
  r=`./docker/docker_es_query.sh "${idx_raw}" _doc 'type:text' 2>/dev/null` || exit 12
  echo "$r" | grep '"status" : 404' && exit 13
  r=`./docker/docker_es_query.sh "${idx}" _doc 'type:tvars AND vname:companies_summary_docs_html' 2>/dev/null` || exit 14
  echo "$r" | grep '"status" : 404' && exit 15
  ./docker/docker_es_query.sh "${idx_raw}" _doc 'type:text'
  ./docker/docker_es_query.sh "${idx}" _doc 'type:tvars AND vname:companies_summary_docs_html'
done
echo 'OK'
