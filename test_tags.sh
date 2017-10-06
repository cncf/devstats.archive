#!/bin/sh
./grafana/influxdb_recreate.sh test
GHA2DB_TAGS_YAML=test_tags.yaml GHA2DB_LOCAL=1 IDB_DB=test ./idb_tags
