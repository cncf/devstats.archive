#!/bin/sh
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_ANNOTATIONS_YAML=annotations.yaml GHA2DB_METRICS_YAML=metrics.yaml GHA2DB_GAPS_YAML=gaps.yaml GHA2DB_LOCAL=1 ./gha2db_sync 'kubernetes,kubernetes-client,kubernetes-incubator'
