#!/bin/bash
GHA2DB_LOCAL=1 GHA2DB_PROJECT=buildpacks GHA2DB_VARS_FN_YAML="sync_vars.yaml" PG_DB=buildpacks PG_HOST="127.0.0.1" PG_PORT=65432 GHA2DB_USE_ES_RAW=1 GHA2DB_USE_ES=1 GHA2DB_ES_URL="http://127.0.0.1:19200" vars || exit 1
GHA2DB_LOCAL=1 GHA2DB_PROJECT=buildpacks GHA2DB_VARS_FN_YAML="vars.yaml" PG_DB=buildpacks PG_HOST="127.0.0.1" PG_PORT=65432 GHA2DB_USE_ES_RAW=1 GHA2DB_USE_ES=1 GHA2DB_ES_URL="http://127.0.0.1:19200" vars || exit 2
GHA2DB_LOCAL=1 GHA2DB_PROJECT=buildpacks GHA2DB_VARS_FN_YAML="sync_vars.yaml" PG_DB=buildpacks PG_HOST="127.0.0.1" PG_PORT=65432 GHA2DB_USE_ES_RAW=1 GHA2DB_USE_ES=1 GHA2DB_ES_URL="http://127.0.0.1:19200" vars || exit 3
./docker/docker_es_query.sh d_buildpacks _doc 'type:tvars AND vname:companies_summary_docs_html'
