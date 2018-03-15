# [[full_name]] Home dashboard

Links:
- Postgres [SQL file](https://github.com/cncf/devstats/blob/master/metrics/[[proj_name]]/events.sql).
- InfluxDB [series definition](https://github.com/cncf/devstats/blob/master/metrics/[[proj_name]]/metrics.yaml) (search for `name: GitHub activity`).
- Grafana dashboard [JSON](https://github.com/cncf/devstats/blob/master/grafana/dashboards/[[proj_name]]/dashboards.json).
- Developer [documentation](https://github.com/cncf/devstats/blob/master/docs/dashboards/dashboards_devel.md).
- Direct [link](https://k8s.[[hostname]]/d/12/dashboards?refresh=15m&orgId=1).

# Description

- First we're displaying links to all CNCF projects defined.
- Next we're showing current project's hourly activity - this is the number of all GitHub events that happened for [[full_name]] project hourly.
- This also includes bots activity (most other dashboards skip bot activity).
- Next we're showing HTML panel that shows all CNCF projects icons and links.
- Next there is a dashboard that shows a list of all dashboards defined for [[full_name]] project.
