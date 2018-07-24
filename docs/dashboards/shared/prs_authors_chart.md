<h1 id="dashboard-header">[[full_name]] PRs authors dashboard</h1>
<p>Links:</p>
<ul>
<li>Metric <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/prs_authors.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/metrics.yaml" target="_blank">series definition</a>. Search for <code>prs_authors</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/[[lower_name]]/prs-authors.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows the number of unique PR authors created in given periods.</li>
<li>Selecting period (for example week) means that dashboard will calculate authors in those periods.</li>
<li>You can select single repository group or summary for all of them.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
<li>We are skipping bots activity, see <a href="https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md" target="_blank">excluding bots</a> for details.</li>
</ul>
