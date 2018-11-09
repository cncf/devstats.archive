#!/bin/bash
./devel/db.sh psql gha -c "refresh materialized view current_state.milestones"
./devel/db.sh psql gha -c "refresh materialized view current_state.issue_labels"
./devel/db.sh psql gha -c "refresh materialized view current_state.prs"
./devel/db.sh psql gha -c "refresh materialized view current_state.issues"
