# Home dashboard

Links:
- Postgres SQL file: [events.sql](https://github.com/cncf/devstats/blob/master/metrics/shared/events.sql).
- TSDB series definition: [metrics.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml) (search for `sql: events`).
- Grafana dashboard JSON: [dashboards.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json).
- User documentation: [dashboards.md](https://github.com/cncf/devstats/blob/master/docs/dashboards/dashboards.md).
- Production version: [view](https://k8s.devstats.cncf.io/d/12/dashboards?refresh=15m&orgId=1).
- Test version: [view](https://k8s.cncftest.io/d/12/dashboards?refresh=15m&orgId=1).

# Description

- First we're displaying links to all CNCF projects defined. Links are defined [here](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json#L91-L270).
- Next we're showing current project's hourly activity:
  - We're quering `gha_events` table to get the total number of GitHub events.
  - For more information about `gha_events` table please check: [gha_events.md](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md).
  - We're summing events hourly.
  - This is a small project activity chart, we're not excluding bots activity here (most other dashboards excludes bot activity).
  - Each row returns single value, we're only groupoing hourly here, so TSDB series name is given [directly](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml) as `events_h`.
- Next we're showing HTML panel that shows all CNCF projects icons and links. Its contents comes from Postgres `[[projects]]` variable
- Next there is a dashboard that shows a list of all dashboards defined for the current project (Kubernetes in this case).
- Next we're showing dashboard docuemntaion. Its contents comes from Postgres `[[docs]]` variable

# Time series

Metric usage is defined in metric.yaml as follows:
```
series_name_or_func: events_h
sql: events
periods: h
```
- It means that we should call Postgres metric [events.sql](https://github.com/cncf/devstats/blob/master/metrics/shared/events.sql).
- We will save: series name `events_h`, query returns just single value for a given hour.
- Grafana query is here: [dashboards.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json#L324): `SELECT \"value\" FROM \"events_h\" WHERE $timeFilter`.
- `$timeFiler` value comes from Grafana date range selector. It is handled by Grafana internally.
- This series is always calculated [last](https://github.com/cncf/devstats/blob/master/context.go#L222), and it is [queried](https://github.com/cncf/devstats/blob/master/cmd/gha2db_sync/gha2db_sync.go#L314) to see last hour calculated when doing a hourly sync.
- Releases comes from Grafana annotations: [dashboards.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json#L69-L82).
- For more details about annotations check [here](https://github.com/cncf/devstats/blob/master/docs/annotations.md).
- Project name is customized per project, it uses `[[full_name]]` template variable [definition](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json#L528-L547) and is [used as project name](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json#L344).
- Dashboard's CNCF projects list with icons and links comes from `[[projects]]` Postgres template variable defined [here](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json#L468-#L487).
- Its definition is [here](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/pdb_vars.yaml#L9-L15).
- It uses this [HTML partial](https://github.com/cncf/devstats/blob/master/partials/projects.html) replacing `[[hostname]]` with then current host name.
- Dashboard's documentation comes from `[[docs]]` Postgres template variable defined [here](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json#L488-#L507).
- Its definition is [here](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/pdb_vars.yaml#L16-L25).
- It uses this [HTML](https://github.com/cncf/devstats/blob/master/docs/dashboards/dashboards.md) replacing `[[hostname]]` with then current host name and `[[full_name]]` with Kubernetes.
- It also replaces `[[proj_name]]` with contents of environment variable `GHA2DB_PROJECT`, using `$GHA2DB_PROJECT` syntax.
- It also replaces `[[url_prefix]]` with direct string `k8s`, using syntax `:k8s`.
- Per project variables are defined using `vars` tools, more info [here](https://github.com/cncf/devstats/blob/master/docs/vars.md).
