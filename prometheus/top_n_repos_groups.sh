#!/bin/sh
PG_DB=prometheus ./runq metrics/prometheus/repo_groups_tags_with_all.sql {{lim}} $1 ' sel.repo_group' " string_agg(sel.repo_group, ',')"
