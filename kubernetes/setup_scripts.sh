#!/bin/sh
# Run this script from the repository top level.
echo "Setting up default postprocess scripts"
PG_DB=gha ./runq util_sql/default_postprocess_scripts.sql
echo "Setting up repository groups postprocess script"
PG_DB=gha ./runq util_sql/repo_groups_postprocess_script.sql
PG_DB=gha ./runq util_sql/repo_groups_postprocess_script_from_repos.sql
