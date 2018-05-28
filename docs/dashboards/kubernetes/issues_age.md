<h1 id="kubernetes-dashboard">[[full_name]] Issues age by SIG and repository groups dashboard</h1>
<p>Links:</p>
<ul>
<li>Metric <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/issues_age.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml" target="_blank">series definition</a>. Search for <code>issues_age</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/issues-age-by-sig-and-repository-groups.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows how many issues were open at given point in time and what was the median open to close time.</li>
<li>Issue SIG is determined by <code>sig/*</code> labels. You can also select summary for all issues by choosing <code>All</code> SIG.</li>
<li>Issue kind is determined by <code>kind/*</code> labels. You can also select summary for all issues by choosing <code>All</code> kind.</li>
<li>Issue priority is determined by <code>priority/*</code> labels. You can also select summary for all issues by choosing <code>All</code> priority.</li>
<li>You can select single repository group or summary for all of them.</li>
<li>Selecting period (for example week) means that dashboard will show number of open issues and median close time in those periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
</ul>
