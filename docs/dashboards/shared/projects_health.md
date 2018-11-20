<h1 id="dashboard-header">[[full_name]] projects health dashboard</h1>
<p>Links:</p>
<ul>
<li>Projects health metric <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/projects_health.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/metrics.yaml" target="_blank">series definition</a>. Search for <code>Projects health</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/[[lower_name]]/projects-health.json" target="_blank">JSON</a>.</li>
<li>HTML <a href="https://github.com/cncf/devstats/blob/master/partials/projects_health.html" target="_blank">partial</a> used to generate table view.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows various projects health metrics.</li>
<li>It uses <a href="https://github.com/cncf/devstats/blob/master/cmd/vars/vars.go" target="_blank">vars</a> program to generate a final HTML view.</li>
</ul>
