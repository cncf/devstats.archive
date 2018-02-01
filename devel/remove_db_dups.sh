#!/bin/sh
./runq util_sql/remove_dups.sql {{table}} gha_issues_pull_requests
./runq util_sql/remove_dups.sql {{table}} gha_texts
