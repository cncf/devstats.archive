<h1 id="dashboard-header">[[full_name]] project statistics dashboard</h1>
<p>Links:</p>
<ul>
<li>Main metric <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/project_stats.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/metrics.yaml" target="_blank">series definition</a>. Search for <code>project_stats</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/[[lower_name]]/project-statistics.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows various project metrics.</li>
<li>Contributor is defined as somebody who made a review, comment, commit or created PR or issue.</li>
<li>You can select last day, month, week etc. range or date range between releases, for example <code>v1.9 - v1.10</code>.</li>
<li>You can select single repository group or summary for all of them.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
<li>We are skipping bots when calculating statistics, see <a href="https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md" target="_blank">excluding bots</a> for details.</li>
</ul>
