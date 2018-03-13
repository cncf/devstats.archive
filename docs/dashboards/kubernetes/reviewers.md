# Kubernetes reviewers dashboard

Links:
- Postgres SQL file: [reviewers.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/reviewers.sql).
- InfluxDB series definition: [metrics.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml#L157-L162).
- Grafana dashboard JSON: [reviewers.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json)
- Production version: [view](https://k8s.devstats.cncf.io/d/38/reviewers?orgId=1).
- Test version: [view](https://k8s.cncftest.io/d/38/reviewers?orgId=1).

# Description

- We're quering `gha_texts` table. It contains all 'texts' from all Kubernetes repositories.
- For more information about `gha_texts` table please check: [docs/tables/gha_texts.md](https://github.com/cncf/devstats/blob/master/docs/tables/gha_texts.md).
- We're creating temporary table 'matching' which contains all event IDs that contain `/lgtm` or `/approve` (no case sensitive) in a separate line (there can be more lines before and/or after this line).
- The exact psql regexp is: `(?i)(?:^|\n|\r)\s*/(?:lgtm|approve)\s*(?:\n|\r|$)`.
- We're only looking for texts created between `{{from}}` and `{{to}}` dates. Values for `from` and `to` will be replaced with final periods described later.
- Then we're creating 'reviews' temporary table that contains all event IDs (`gha_events`) that belong to GitHub event type: `PullRequestReviewCommentEvent`.
- For more information about `gha_events` table please check: [docs/tables/gha_event.md](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md).
- Then comes the final select which returns multiple rows (one for All repository groups combined and then one for each repository group).
- Each row returns single value, so the metric type is: `multi_row_single_column`.
- Each row is in the format column 1: `reviewers,RepoGroupName`, column 2: `NumberOfReviewersInThisRepoGroup`. Number of rows is N+1, where N=number of repo groups. One additional row for `reviewers,All` that contains number of repo groups for all repo groups.
- Value for each repository group is calculated as a number of distinct actor logins who:
- Are not bots (see [excluding bots](https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md).)
- Added `lgtm` or `approve` label in a given period (`gha_issues_events_labels` table)
- For more information about `gha_issues_events_labels` table please check: [docs/tables/gha_issues_events_labels.md](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues_events_labels.md).
- Added text matching given regexp.
- Added PR review comment (event type `PullRequestReviewCommentEvent`).
- Event belong to a given repository group (in repo group part of the SQL, this is not checked for 'All' repo group that conatins data from all repository groups).
- Finally temp tables are dropped.
- For repository group definition check: [repository groups](https://github.com/cncf/devstats/blob/master/docs/repository_groups.md) (table `gha_events` and commit files for file level granularity repo groups).
- For more information about `gha_repos` table please check: [docs/tables/gha_repos.md](https://github.com/cncf/devstats/blob/master/docs/tables/gha_repos.md).

# Periods and Influx series

Metric usage is defined in metric.yaml as follows:
```
series_name_or_func: multi_row_single_column
sql: reviewers
periods: d,w,m,q,y
aggregate: 1,7
skip: w7,m7,q7,y7
```
- It means that we should call Postgres metric [reviewers.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/reviewers.sql).
- We should expect multiple rows each with 2 columns: 1st defines output Influx series name, 2nd defines value.
- See [here](https://github.com/cncf/devstats/blob/master/docs/periods.md) for periods definitions.
- The final InfluxDB series name would be: `reviewers_[[repogroup]]_[[period]]`. Where [[period]] will be from d,w,m,q,y,d7 and [[repogroup]] will be from 'all,apps,contrib,kubernetes,...', see [repository groups](https://github.com/cncf/devstats/blob/master/docs/repository_groups.md) for details.
- Repo group name returned by Postgres SQL is normalized (downcased, removed special chars etc.) to be usable as a Influx series name [here](https://github.com/cncf/devstats/blob/master/cmd/db2influx/db2influx.go#L112) using [this](https://github.com/cncf/devstats/blob/master/unicode.go#L23).
- Final query is here: [reviewers.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json#L116): `SELECT "value" FROM "autogen"."reviewers_[[repogroup]]_[[period]]" WHERE $timeFilter`.
- `$timeFiler` value comes from Grafana date range selector. It is handled by Grafana internally.
- `[[period]]` comes from Variable definition in dashboard JSON: [reviewers.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json#L188-L234).
- `[[repogroup]]` comes from Grafana variable that uses influx tags values: [reviewers.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json#L236-L274).
- You are selecting `repogroup_name` from Grafana UI (this drop-down is visible), values are: All,Apps,Cluster lifecycle, ...
- Then Grafana uses `repogroup` which is a hidden variable that normalizes this name using other tag value that matches `repogroup_name`.
- To see more details about repository group tags, and all other tags check [tags.md](https://github.com/cncf/devstats/blob/master/docs/tags.md).
- Releases comes from Grafana annotations: [reviewers.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json#L43-L55).
- For more details about annotations check [here](https://github.com/cncf/devstats/blob/master/docs/annotations.md).
- Project name is customized per project, it uses `[[full_name]]` template variable [definition](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json#L275-L293) and is [used as project name](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json#L78).
- Per project variables are defined using `idb_vars` tool, more info [here](https://github.com/cncf/devstats/blob/master/docs/vars.md).
