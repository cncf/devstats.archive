#!/bin/bash
PG_DB=opencontainers ./runq metrics/opencontainers/repo_groups_tags_with_all.sql {{lim}} $1 ' sel.repo_group' " string_agg(sel.repo_group, ',')"
