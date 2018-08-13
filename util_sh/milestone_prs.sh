#!/bin/bash
if ( [ -z "$1" ] || [ -z "$PG_PASS" ] )
then
  echo "PG_PASS=... $0 milestone_name"
  exit 1
fi
sudo -u postgres psql -c "refresh materialized view current_state.prs"
GHA2DB_SKIPTIME=1 GHA2DB_SKIPLOG=1 ./runq util_sql/milestone_prs.sql {{milestone}} "$1"
