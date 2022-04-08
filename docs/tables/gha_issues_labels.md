# `gha_issues_labels` table

- This is a table that holds labels set on an issue/PR in a given moment in time.
- GitHub is not generating any events when label set on an issue/PR changes (adding, removing labels).
- When next event (like issue comment) on that issue happens (which can happen a month later) this table will contain new labels set.
- This is a variable table, for details check [variable table](https://github.com/cncf/devstats/blob/master/docs/tables/variable_table.md).
- It contains about 3.7M records as of Mar 2018.
- [ghaapi2db](https://github.com/cncf/devstats/tree/master/cmd/ghapi2db/ghapi2db.go) tool is creating new labels set entries when it detects that some issue/PR has wrong labels set or wrong milestone.
- It happens when somebody changes label and/or milestone without commenting on the issue, or after commenting. Change label/milestone is not creating any GitHub event, so the final issue/PR state can be wrong.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L533-L554).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L354-L366).
- Its primary key is `(event_id, issue_id, label_id)`.

# Columns

Columns starting with `dup_` are duplicated from other tables, to speedup processing and allow saving joins.
- `issue_id`: Issue ID, see [gha_issues](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues.md).
- `event_id`: GitHub event ID, see [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md).
- `label_id`: Label ID, see [gha_labels](https://github.com/cncf/devstats/blob/master/docs/tables/gha_labels.md).
- `dup_actor_id`: GitHub actor ID (GitHub event creator - usually issue comment creator, not necesarilly someone who addded/removed label), see [gha_actors](https://github.com/cncf/devstats/blob/master/docs/tables/gha_actors.md).
- `dup_actor_login`: Duplicated GitHub actor login (from [gha_actors](https://github.com/cncf/devstats/blob/master/docs/tables/gha_actors.md) table).
- `dup_repo_id`: GitHub repository ID, see [gha_repos](https://github.com/cncf/devstats/blob/master/docs/tables/gha_repos.md).
- `dup_repo_name`: Duplicated GitHub repository name (note that repository name can change in time, but repository ID remains the same, see [gha_repos](https://github.com/cncf/devstats/blob/master/docs/tables/gha_repos.md) table).
- `dup_type`: GitHub event type, can be: PullRequestReviewEvent, PullRequestReviewCommentEvent, MemberEvent, PushEvent, ReleaseEvent, CreateEvent, GollumEvent, TeamAddEvent, DeleteEvent, PublicEvent, ForkEvent, PullRequestEvent, IssuesEvent, WatchEvent, IssueCommentEvent, CommitCommentEvent.
- `dup_created_at`: Event creation date.
- `dup_issue_number`: Issue number, see [gha_issues](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues.md).
- `dup_label_name`: Label name, see [gha_labels](https://github.com/cncf/devstats/blob/master/docs/tables/gha_labels.md).
