<h1 id="kubernetes-dashboard">[[full_name]] Overall Project Statistics dashboard</h1>
<p>Links:</p>
<ul>
<li>Main metric <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/project_stats.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml" target="_blank">series definition</a>. Search for <code>project_stats</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/overall-project-statistics.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows various project metrics.</li>
<li>Contributor is defined as somebody who made a commit or created PR or issue.</li>
<li>Committer is somebody who pushed the commit into the repository, commit author is somebody who made/authored a commit/PR pushed by the committer, this can be the same person or not.</li>
<li>You can select last day, month, week etc. range or date range between releases, for example <code>v1.9 - v1.10</code>.</li>
<li>You can select single repository group or summary for all of them.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
<li>We are skipping bots when calculating statistics, see <a href="https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md" target="_blank">excluding bots</a> for details.</li>
</ul>
