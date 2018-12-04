#!/bin/bash
GHA2DB_LOCAL=1 ./runq util_sql/remove_dups.sql {{table}} gha_issues_pull_requests
GHA2DB_LOCAL=1 ./runq util_sql/remove_dups.sql {{table}} gha_texts
