# `gha_issues_pull_requests` table

- This is a compute table, that contains data to connect issues with PRs.
- It contains issue ID, PR ID and shared number (PR & Issue).
- It contains duplicated columns to allow queries on this single table instead of joins.
- It needs postprocessing that is defined in a standard project's setup script. It is updated in postprocess every hour.
- Setup scripts is called by main Postgres init script, for Kubernetes it is: [kubernetes/psql.sh](https://github.com/cncf/devstats/blob/master/kubernetes/psql.sh#L14)).
- It runs [kubernetes/setup_scripts.sh](https://github.com/cncf/devstats/blob/master/kubernetes/setup_scripts.sh#L4). This is `{{projectname}}/setup_scripts.sh` for other projects.
- SQL script [util_sql/postprocess_issues_prs.sql](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_issues_prs.sql) is scheduled to run every hour by: [util_sql/default_postprocess_scripts.sql](https://github.com/cncf/devstats/blob/master/util_sql/default_postprocess_scripts.sql#L3).
- It is called by [this code](https://github.com/cncf/devstats/blob/master/structure.go#L1162-L1187) that uses [gha_postprocess_scripts](https://github.com/cncf/devstats/blob/master/docs/tables/gha_postprocess_scripts.md) table to get postprocess scripts to run. One of them, defined above creates entries for `gha_issues_events_labels` table every hour.
- It contains about 69k records as of Mar 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L1135-L1149).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L375-L382).
- It has no primary kay, it only connects Issues with PRs.
- It contains data from [issues](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues.md), [PRs](https://github.com/cncf/devstats/blob/master/docs/tables/gha_pull_requests.md) tables.
- When adding a project to an existing database that contains merge result from multiple projects, you need to manually remove eventual duplicates using: [./devel/remove_db_dups.sh](https://github.com/cncf/devstats/blob/master/devel/remove_db_dups.sh), as suggested by [cmd/merge_dbs/merge_dbs.go](https://github.com/cncf/devstats/blob/master/cmd/merge_dbs/merge_dbs.go#L197).

# Columns

- `issue_id`: GitHub issue ID. See [gha_issues](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues.md) table.
- `pull_request_id`: GitHub Pull Request ID. See [gha_pull_requests](https://github.com/cncf/devstats/blob/master/docs/tables/gha_pull_requests.md) table.
- `number`: This is both Issue and PRs number. You can use #number in GitHub to refer to PR/Issue.
- `repo_id`: GitHub repository ID (from [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md)).
- `repo_name`: GitHub repository name (note that repository name can change in time, while repository ID cannot).
- `created_at`: Event creation date, comes from [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md).
