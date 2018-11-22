#!/bin/bash
GHA2DB_LOCAL=1 GHA2DB_PROJECT=buildpacks PG_DB=buildpacks PG_HOST="127.0.0.1" PG_PORT=65432 GHA2DB_USE_ES_RAW=1 GHA2DB_USE_ES=1 GHA2DB_ES_URL="http://127.0.0.1:19200" ./gha2es "$1" "$2" today now
#./docker/docker_es_query.sh d_buildpacks _doc 'type:tvars'
