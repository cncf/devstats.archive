<h1 id="dashboard-header">[[full_name]] issues age dashboard</h1>
<p>Links:</p>
<ul>
<li>Metric <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/issues_age.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/metrics.yaml" target="_blank">series definition</a>. Search for <code>issues_age</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/[[lower_name]]/issues-age.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows median time to close issues opened in selected periods and average number of closed issues opened in those periods.</li>
<li>Selecting period (for example week) means that dashboard will calculate data for issues opened in those periods.</li>
<li>You can select single repository group or summary for all of them.</li>
<li>You can select all issues or issues with a specific priority.</li>
<li>Issue priority is defined as a label <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/labels_priorities_tags_with_all.sql" target="_blank">here</a>.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
</ul>
