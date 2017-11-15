#!/bin/sh
GHA2DB_LOCAL=1 GHA2DB_PROJECT=fluentd PG_DB=fluentd IDB_DB=fluentd ./gha2db_sync
