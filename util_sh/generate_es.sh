#!/bin/bash
PG_PASS=redacted GHA2DB_PROJECTS_OVERRIDE="+cncf" ONLY="cncf prometheus" GHA2DB_ES_URL="https://url:port" ./devel/reinit_es_only.sh
