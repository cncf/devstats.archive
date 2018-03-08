# `gha_pull_requests` table

- This is a table that holds GitHub PR state at a given point in time (`event_id` refers to [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md)).
- This is a variable table, for details check [variable table](https://github.com/cncf/devstats/blob/master/docs/tables/variable_table.md).
- It contains about 403K records but only 76K distinct PR IDs (Mar 2018 state) - this means that there are about 5-6 events per PR on average.
- Its primary key is `(event_id, id)`.
- There is a special [compute table](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues_pull_requests.md) that connects Issues with PRs.

# Columns

Most important columns are:
- `id`: GitHub Pull Request ID.
- `event_id`: GitHub event ID, see [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md).
- `body`: PR text.
- `created_at`: PR creation date.
- `closed_at`: PR close date. Note that this table holds PR state in time, so for some event this date will be null, for some other it will be set.
- `merged_at`: PR merge date (can be null for all events). Note that this table holds PR state in time, so for some event this date will be null, for some other it will be set.
- `user_id`: GitHub user ID performing action on the issue.
- `milestone_id`: Milestone ID, see [gha_milestones](https://github.com/cncf/devstats/blob/master/docs/tables/gha_milestones.md).
- `number`: PR number - this is an unique number within single repository. There will be an entry in [gha_issues_pull_requests](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues_pull_requests.md) and [gha_issues](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues.md) with the same `number` and `repo_id` - PRs are stored on that tables too.
- `state`: `open` or `closed` at given GitHub event `event_id` date.
- `merged`: PR merged state at given `event_id` time, can be true (merged) or false, null (not merged).
- `merged_by_id`: GitHub user who merged this PR or null.
- `merge_commit_sha`: SHA of a merge commit, if merged, see [gha_commits](https://github.com/cncf/devstats/blob/master/docs/tables/gha_commits.md).
- `title`: Issue title.
- `assignee_id`: Assigned GitHub user, can be null.
- `base_sha`: PRs base branch SHA, see [gha_commits](https://github.com/cncf/devstats/blob/master/docs/tables/gha_commits.md).
- `head_sha`: PRs SHA, see [gha_commits](https://github.com/cncf/devstats/blob/master/docs/tables/gha_commits.md).
