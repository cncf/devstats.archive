sudo -u postgres psql gha -c "refresh materialized view current_state.milestones"
sudo -u postgres psql gha -c "refresh materialized view current_state.issue_labels"
sudo -u postgres psql gha -c "refresh materialized view current_state.prs"
sudo -u postgres psql gha -c "refresh materialized view current_state.issues"
