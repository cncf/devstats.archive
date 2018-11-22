#!/bin/bash
if [ -z "${ES_URL}" ]
then
  ES_URL="http://localhost:19200"
fi
if [ -z "$1" ]
then
  echo "$0: please provide index name as a first argument"
  echo 'Raw (unaggregated) indexes d_raw_projname contain type:(pr OR issue OR commit OR text)'
  echo 'Indexes d_projname contain aggregated DevStats metrics + tags, annotations, variables, documentations etc.'
  exit 1
fi
if [ -z "$2" ]
then
  echo "$0: please provide type name as a second argument"
  echo 'The default type name is _doc'
  exit 2
fi
if [ -z "$3" ]
then
  echo "$0: please provide search query as a third argument:"
  echo 'type:tvars AND vname:full_name'
  echo 'type:trepo_groups AND repo_group_name:\"cncf/devstats\"'
  echo 'type:sactivity_repo_groups AND period:y'
  echo 'type:itvars AND iname:vvalue AND tag_time:\"2014-01-01 13:00:00\"'
  echo 'type:sactivity_repo_groups AND data.ivalue:0.14'
  echo 'type:isactivity_repo_groups AND period:y AND name:(\"cncf\/devstats\" OR \"cncf\/gitdm\")'
  echo 'type:iswatchers AND period:d AND series:watchcncflandscapewatch'
  echo 'type:iscompany_activity AND period:q AND series:companyallcommits AND name:(Google OR \"Red Hat\")'
  echo 'type:commit AND committer_login:lukaszgryglicki'
  echo 'type:issue AND milestone_title:\"v1.12\"'
  echo 'type:issue AND repo_group:Kubernetes AND milestone_title:v1.12'
  echo 'type:pr AND merged:true'
  echo 'type:tes_periodsAND devstats_period:d7'
  echo 'type:ishcom AND period:q AND series:hcomcontributions'
  echo 'type:(issue OR pr)'
  echo 'type:text AND full_body:\"kubernetes bug\"'
  exit 3
fi
curl -XPOST -H 'Content-Type: application/json' "${ES_URL}/${1}/${2}/_search?pretty" -d "{\"query\":{\"query_string\":{\"query\":\"${3}\"}}}"
