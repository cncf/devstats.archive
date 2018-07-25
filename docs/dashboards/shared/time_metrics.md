<h1 id="dashboard-header">[[full_name]] time metrics dashboard</h1>
<p>Links:</p>
<ul>
<li>Metric <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/time_metrics.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/metrics.yaml" target="_blank">series definition</a>. Search for <code>time_metrics</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/[[lower_name]]/time-metrics.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows median and 85the percentile of open to merge time for PRs created in given periods.</li>
<li>You can select single repository group or summary for all of them.</li>
<li>Selecting period (for example week) means that dashboard will calculate PRs open to merge time in those periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
</ul>
