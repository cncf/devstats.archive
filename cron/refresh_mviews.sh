#!/bin/bash
if [ -z "$PG_HOST" ]
then
  PG_HOST=127.0.0.1
fi

if [ -z "$PG_PORT" ]
then
  PG_PORT=5432
fi
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" gha -c "refresh materialized view current_state.milestones"
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" gha -c "refresh materialized view current_state.issue_labels"
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" gha -c "refresh materialized view current_state.prs"
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" gha -c "refresh materialized view current_state.issues"
