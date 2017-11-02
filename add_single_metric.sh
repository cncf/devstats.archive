#!/bin/sh
GHA2DB_CMDDEBUG=1 GHA2DB_RESETIDB=1 GHA2DB_ANNOTATIONS_YAML=test_annotations.yaml GHA2DB_METRICS_YAML=test_metrics.yaml GHA2DB_GAPS_YAML=test_gaps.yaml GHA2DB_TAGS_YAML=test_tags.yaml GHA2DB_LOCAL=1 ./gha2db_sync
