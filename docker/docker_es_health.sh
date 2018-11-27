#!/bin/bash
r=`./docker/docker_es_indexes.sh 2>/dev/null` || exit 1
echo "$r" | grep 404 && exit 2
echo $r
r=`./docker/docker_es_types.sh d_lfn 2>/dev/null` || exit 3
echo "$r" | grep 404 && exit 4
echo $r
r=`./docker/docker_es_types.sh d_raw_lfn 2>/dev/null` || exit 5
echo "$r" | grep 404 && exit 6
echo $r
r=`./docker/docker_es_values.sh d_lfn _doc 2>/dev/null` || exit 7
echo "$r" | grep 404 && exit 8
echo $r
r=`./docker/docker_es_values.sh d_raw_lfn _doc 2>/dev/null` || exit 9
echo "$r" | grep 404 && exit 10
echo $r
r=`./docker/docker_es_query.sh d_raw_lfn _doc 'type:text AND full_body:build' 2>/dev/null` || exit 11
echo "$r" | grep 404 && exit 12
r=`./docker/docker_es_query.sh d_lfn _doc 'type:tvars AND vname:companies_summary_docs_html' 2>/dev/null` || exit 13
echo "$r" | grep 404 && exit 14
./docker/docker_es_query.sh d_raw_lfn _doc 'type:text AND full_body:build'
./docker/docker_es_query.sh d_lfn _doc 'type:tvars AND vname:companies_summary_docs_html'
echo 'OK'
