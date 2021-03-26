<h1 id="kubernetes-dashboard">[[full_name]] PR Time to Engagement dashboard</h1>
<p>Links:</p>
<ul>
<li>Metric (repo groups) <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/first_non_author_activity.sql" target="_blank">SQL file</a>.</li>
<li>Metric (repositories) <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/first_non_author_activity_repos.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml" target="_blank">series definition</a>. Search for <code>first_non_author_activity</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/pr-time-to-engagement.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows median, 15th and 85th percentices of time from creation to first non-author activity on issues and PRs created in given periods.</li>
<li>You can select single repository group or summary for all of them (for 2 top panels showing repository groups).</li>
<li>You can repository for 2 bottom panels showing per single repository statistics.</li>
<li>You can select PRs with a specific <code>kind/*</code> label or summary for all of them.</li>
<li>Selecting period (for example week) means that dashboard will data for PRs and issues created in those periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
<li>We are skipping bots activity, see <a href="https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md" target="_blank">excluding bots</a> for details.</li>
</ul>
