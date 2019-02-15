#!/bin/bash
if [ -z "$ES_URL" ]
then
  echo "$0: you need to set ES_URL=..."
  exit 1
fi
./docker/docker_es_query.sh d_kubernetes _doc "type:sannotations AND title:v1.13.0"
./docker/docker_es_query.sh d_kubernetes _doc "type:tvars AND vname:full_name"
./docker/docker_es_query.sh d_kubernetes _doc "type:tvars AND vname:sig_mentions_docs_html"
./docker/docker_es_query.sh d_kubernetes _doc "type:tsig_mentions_texts AND sig_mentions_texts_value:apps"
./docker/docker_es_query.sh d_kubernetes _doc "type:issig_mentions AND name:api-machinery AND period:y AND ivalue:4599"
./docker/docker_es_query.sh d_kubernetes _doc "type:tquick_ranges AND quick_ranges_suffix:a_0_1"
./docker/docker_es_query.sh d_kubernetes _doc "type:tvars AND vname:project_stats_docs_html"
./docker/docker_es_query.sh d_kubernetes _doc "type:tall_repo_groups AND all_repo_group_value:signode"
./docker/docker_es_query.sh d_kubernetes _doc "type:ispstat AND series:pstatsignode AND period:y10 AND svalue:Contributors"
./docker/docker_es_query.sh d_kubernetes _doc "type:tvars AND vname:tzs_stats_docs_html"
./docker/docker_es_query.sh d_kubernetes _doc "type:ttz_offsets AND tz_offset:1.0"
./docker/docker_es_query.sh d_kubernetes _doc "type:istz AND period:y AND series:tzsignodecontributions AND name:1.0 AND ivalue:3414"
