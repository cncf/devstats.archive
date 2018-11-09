#!/bin/bash
db.sh psql gha -c "refresh materialized view current_state.milestones"
db.sh psql gha -c "refresh materialized view current_state.issue_labels"
db.sh psql gha -c "refresh materialized view current_state.prs"
db.sh psql gha -c "refresh materialized view current_state.issues"
