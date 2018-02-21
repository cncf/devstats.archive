# `gha_issues_events_labels` table

- This is a compute table, that contains shortcuts to issues labels connected with events (for metrics speedup).
- It contains many duplicated columns to allow queries on this single table instead of joins.
- It needs postprocessing that is defined in a standard project's setup script. It is updated in postprocess every hour.
- Setup scripts is called by main Postgres init script, for Kubernetes it is: [kubernetes/psql.sh](https://github.com/cncf/devstats/blob/master/kubernetes/psql.sh#L14).
- It runs [kubernetes/setup_scripts.sh](https://github.com/cncf/devstats/blob/master/kubernetes/setup_scripts.sh#L4). This is `{{projectname}}/setup_scripts.sh` for other projects.
- SQL script [util_sql/postprocess_labels.sql](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_labels.sql) is scheduled to run every hour by: [util_sql/default_postprocess_scripts.sql](https://github.com/cncf/devstats/blob/master/util_sql/default_postprocess_scripts.sql#L2).
- It is called by [this code](https://github.com/cncf/devstats/blob/master/structure.go#L1162-L1187) that uses [gha_postprocess_scripts](https://github.com/cncf/devstats/blob/master/docs/tables/gha_postprocess_scripts.md) table to get postprocess scripts to run. One of them, defined above creates entries for `gha_issues_events_labels` table every hour.
- It contains about 3.6M records as of Feb 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L1077-L1096).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L333-L345).
- Its primary key is `(issue_id, label_id, event_id)`.
- It contains data from [labels](https://github.com/cncf/devstats/blob/master/docs/tables/gha_labels.md), [issue_labels](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues_labels.md) tables.

# Columns

- `event_id`: GitHub event ID. This ID is artificially generated for pre-2015 events.
- `issue_id`: .
- `label_id`: .
- `label_name`: .
- `created_at`: .
- `actor_id`: .
- `actor_login`: .
- `repo_id`: .
- `repo_name`: .
- `type`: .
- `issue_number`: .
