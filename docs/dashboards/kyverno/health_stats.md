<h1 id="dashboard-header">[[full_name]] community health dashboard</h1>
<p>Links:</p>
<ul>
<li>Stars metric <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/watchers_by_alias.sql" target="_blank">SQL file</a>.</li>
<li>Other metrics <a href="https://github.com/cncf/devstats/blob/master/metrics/kyverno/community_health.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kyverno/metrics.yaml" target="_blank">series definition</a>. Search for <code>community_health</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/[[lower_name]]/community-health.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows counts for stargazers, issue creators, code committers, code commenters for a given repository.</li>
<li>Code commenter is someone who commentented on code commit, made a PR review or comment.</li>
<li>It shows those values changing over time with daily resolution, also includes summory for all project repositories combined.</li>
<li>Bots are skipped when calculating statistics, see <a href="https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md" target="_blank">excluding bots</a> for details.</li>
</ul>
