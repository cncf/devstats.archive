# `gha_postprocess_scripts` table

- This is a special table, not created by any GitHub archive (GHA) event.
- It contains informations about which scripts should be executed every hour after data from GitHub archives is fetched for the next hour.
- Records in this table are inserted once, as a part of `{{project_name}}/psql.sh` (for Kubernetes it is [kubernetes/psql.sh](https://github.com/cncf/devstats/blob/master/kubernetes/psql.sh#L14)).
- For every project `{{project_name}}/setup_scripts.sh` is used to add records to this table (for Kubernetes it is [kubernetes/setup_scripts.sh](https://github.com/cncf/devstats/blob/master/kubernetes/setup_scripts.sh)).
- It contains just few records (5 for Kubernetes, 4 for other projects).
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L1031-L1043).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L538-L541).
- This table is used to create/update values in [gha_issues_events_labels](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues_events_labels.md), [gha_texts](https://github.com/cncf/devstats/blob/master/docs/tables/gha_texts.md), [gha_events_commits_files](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events_commits_files.md), [gha_issues_pull_requests](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues_pull_requests.md).
- This table is used by [this code](https://github.com/cncf/devstats/blob/master/structure.go#L1162-L1187) get postprocess scripts to run.
- Default postprocess scripts are defined by [kubernetes/setup_scripts.sh](https://github.com/cncf/devstats/blob/master/kubernetes/setup_scripts.sh#L4). This is `{{projectname}}/setup_scripts.sh` for other projects.
- Its primary key is `(ord, path)`.

# Columns

- `ord`: Ordinal number used to decide order of scripts to run.
- `path`: Script path, for example `util_sql/postprocess_repo_groups.sql`.
