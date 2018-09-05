CREATE INDEX issue_labels_issue_id ON current_state.issue_labels USING btree (issue_id);
CREATE INDEX issue_labels_label_parts ON current_state.issue_labels USING btree (prefix, label);
CREATE INDEX issue_labels_prefix ON current_state.issue_labels USING btree (prefix);
CREATE INDEX issues_id ON current_state.issues USING btree (id);
CREATE INDEX issues_milestone ON current_state.issues USING btree (milestone);
CREATE INDEX issues_number ON current_state.issues USING btree (number);
CREATE INDEX milestones_id ON current_state.milestones USING btree (id);
CREATE INDEX milestones_name ON current_state.milestones USING btree (milestone);
