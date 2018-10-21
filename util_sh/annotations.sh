#!/bin/bash
GHA2DB_PROJECT=kubernetes GHA2DB_DEBUG=1 GHA2DB_USE_ES=1 GHA2DB_ES_URL="http://127.0.0.1:9200" GHA2DB_SKIPTSDB=1 ./shared/annotations.sh
