#!/bin/bash
GHA2DB_LOCAL=1 GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 GHA2DB_CSVOUT="cncf_repos.csv" PG_DB=cncf ./runq ./util_sql/current_repo_names.sql
GHA2DB_LOCAL=1 GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 GHA2DB_CSVOUT="all_project_repos.csv" PG_DB=allprj ./runq ./util_sql/current_repo_names.sql
