<h1 id="dashboard-header">[[full_name]] time to triage an issue dashboard</h1>
<p>Links:</p>
<ul>
<li>Metric <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/time_to_assign_issue.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/[[lower_name]]/metrics.yaml" target="_blank">series definition</a>. Search for <code>time_to_assign_issue</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/[[lower_name]]/time-to-triage-an-issue.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows median, 15th and 85th percentiles of time before issue creation and assigning someone to the issue.</li>
<li>It skips self-assignments and assignments happening in first 30s after issue creation.</li>
<li>You can choose repository group (or all of them) and aggregation period.</li>
<li>Selecting period (for example week) means that dashboard will calculate percentiles in those periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
</ul>
