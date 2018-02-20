# Influx tags

- You can use InfluxDB tags to define drop-down values (variables) in Grafana dashboards.
- Some drop-downs can be hardcoded, without using influxDB, for example `Period` drop-down is usually [hardcoded](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json#L188-L234) and has the same values as in [metrics.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml#L157-L162).
- Sometimes we need drop-down values to be fetched from InfluxDB, but this is not a time-series data, we're using tags in such cases.
- All tags are defined per project in `idb_tags.yaml` file, for example for Kubernetes it is [metrics/kubernetes/idb_tags.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/idb_tags.yaml).
- For example for "Repository" group we can use [repogroup_name](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json#L235-L254) which uses [this tag](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/idb_tags.yaml#L21).
- Then we can create [repogroup](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json#L255-L274) which uses `repogroup_name` defined above and [this tag](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/idb_tags.yaml#L22).
- They both use SQL defined [here](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/idb_tags.yaml#L19) to get vales from Postgres: [metrics/kubernetes/repo_groups_tags_with_all.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/repo_groups_tags_with_all.sql).
- Postgres SQLs that returns data for InfluxDB tags has `tags` in their name, for example `Companies` drop-down tags: [metric/kubernetes/companies_tags.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/companies_tags.sql).
- Some tags use `{{lim}}` template value, this is the nuymber of tag values to return (for most items it is limited to 69), see template evaluation [cmd/idb_tags/idb_tags.go](https://github.com/cncf/devstats/blob/master/cmd/idb_tags/idb_tags.go#L107).
- There is also a special `os_hostname` tag that evaluates to current machine's hostname, it is calculated [here](https://github.com/cncf/devstats/blob/master/cmd/idb_tags/idb_tags.go#L74-L89).
- It can be used to generate links to current host name (production or test), you can use [Grafana variable that uses InfluxDB tag](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json#L421-L438) to use it as link basename, like [here](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json#L84).
- Hostname tag is always available on all projects.
