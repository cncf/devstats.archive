# `gha_issues` table

- This is a table that holds GitHub issue state at a given point in time (`event_id` refers to [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md)).
- This is a variable table, for details check [variable table](https://github.com/cncf/devstats/blob/master/docs/tables/variable_table.md).
- [ghaapi2db](https://github.com/cncf/devstats/tree/master/cmd/ghapi2db/ghapi2db.go) tool is creating new issue state entries (artificial) when it detects that some issue/PR has wrong labels set or wrong milestone.
- It happens when somebody changes label and/or milestone without commenting on the issue, or after commenting. Change label/milestone is not creating any GitHub event, so the final issue/PR state can be wrong.
- It contains about 1.2M records but only 115K distinct issue IDs (Mar 2018 state) - this means that there are about 10 events per issue on average.
- Its primary key is `(event_id, id)`.
- There is a special [compute table](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues_pull_requests.md) that connects Issues with PRs.

# Columns

Most important columns are:
- `id`: GitHub Issue ID.
- `event_id`: GitHub event ID, see [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md).
- `body`: issue text.
- `created_at`: Issue creation date.
- `closed_at`: Issue close date. Note that this table holds Issue state in time, so for some event this date will be null, for some other it will be set. If issue was closed/opened multiple times - all historical close dates will be stored here.
- `milestone_id`: Milestone ID, see [gha_milestones](https://github.com/cncf/devstats/blob/master/docs/tables/gha_milestones.md).
- `number`: Issue number - this is an unique number within single repository.
- `state`: `open` or `closed` at given GitHub event `event_id` date.
- `title`: Issue title.
- `user_id`: GitHub user ID performing action on the issue.
- `assignee_id`: Assigned GitHub user, can be null.
- `is_pull_request`: true - this is a PR, false - this is an Issue. PRs are stored on this table too, but they have an additional record in [gha_pull_requests](https://github.com/cncf/devstats/blob/master/docs/tables/gha_pull_requests.md).
