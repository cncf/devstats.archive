# Kubernetes reviewers dashboard

Links:
- Metric [SQL file](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/reviewers.sql).
- InfluxDB [series definition](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml#L157-L162).
- Grafana dashboard [JSON](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json).
- Developer [documentation](https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/reviewers_devel.md).

# Description

- This dashboard shows the number of reviewers for a selected repository group or for all repository groups combined.
- Reviewers is defined as someone who added pull request review comment(s) or added `/lgtm` or `/approve` text or added `lgtm` or `approve` label.
- You can filter by repository group and period.
- Selecting period (for example Week) means that dahsboard will count distinct users who made a review in this periods.
- See [here](https://github.com/cncf/devstats/blob/master/docs/periods.md) for more informations about periods.
- See [here](https://github.com/cncf/devstats/blob/master/docs/repository_groups.md) for more informations about repository groups.
- We are skipping bots when calculating numbe rof reviewers, see [excluding bots](https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md) for details.
