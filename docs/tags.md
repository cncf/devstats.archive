# Tags

- You can use tags to define drop-down values (variables) in Grafana dashboards.
- Some drop-downs can be hardcoded, without using tags, for example `Period` drop-down is usually hardcoded and has the same values as in [metrics.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml).
- The same values means Grafana's variable JSON has the same period definitions as defined by `period`, `aggregate` and `skip` properties of a given metric in `metrics.yaml`.
- Sometimes we need drop-down values to be fetched from the database.
- All tags are defined per project in `tags.yaml` file, for example for Kubernetes it is [metrics/kubernetes/tags.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/tags.yaml).
- For example for "Repository" group we can use `repogroup_name` uses [tag](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/tags.yaml).
- Then we can create `repogroup` which uses `repogroup_name` defined above.
- One tag returns unprocessed names like `A,A b c, d/e/f` the other returns normalized like `a,a_b_c,d_e_f` which can be used as series name. Example above shows drop down values with unprocessed names, but uses hidden variable that returns current selection normalized for series name in Grafana's data query.
- They both use SQL defined [here](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/tags.yaml) to get vales from Postgres: [metrics/kubernetes/repo_groups_tags_with_all.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/repo_groups_tags_with_all.sql).
- Postgres SQLs that returns data for tags has `tags` in their name, for example `Companies` drop-down tags: [metric/kubernetes/companies_tags.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/companies_tags.sql).
- Some tags use `{{lim}}` template value, this is the number of tag values to return (for most items it is limited to 69), see template evaluation [cmd/tags/tags.go](https://github.com/cncf/devstats/blob/master/cmd/tags/tags.go).
- There is also a special `os_hostname` tag that evaluates to current machine's hostname, it is calculated [here](https://github.com/cncf/devstats/blob/master/cmd/tags/tags.go).
- It can be used to generate links to current host name (production or test), you can use [Grafana variable that uses tag](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json#L421-L438) to use it as link basename, like [here](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json#L84).
- Hostname tag is always available on all projects.
