<h1 id="kubernetes-dashboard">[[full_name]] Open PR Age By Repository Group dashboard</h1>
<p>Links:</p>
<ul>
<li>Metric <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/prs_age.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml" target="_blank">series definition</a>. Search for <code>prs_age</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/open-pr-age-by-repository-group.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows the chart of how many PRs were open in selected periods and what was the median PR open to merge time.</li>
<li>You can select single repository group or summary for all of them.</li>
<li>You can select PRs with a specific <code>kind/*</code> label or summary for all of them.</li>
<li>Selecting period (for example week) means that dashboard will show number of open PRs and median open to merge time in those periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
</ul>
