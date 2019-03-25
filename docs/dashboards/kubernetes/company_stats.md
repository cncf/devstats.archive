<h1 id="kubernetes-dashboard">[[full_name]] Company statistics by repository groups dashboard</h1>
<p>Links:</p>
<ul>
<li>Metric <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/company_activity.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml" target="_blank">series definition</a>. Search for <code>company_activity</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/company-statistics-by-repository-group.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows various companies metrics.</li>
<li>Contributor is defined as somebody who made a review, comment, commit, created PR or issue.</li>
<li>Contribution is a review, comment, commit, issue or PR.</li>
<li>All activity counts all GitHub events.</li>
<li>You can select all companies or choose some subset of them.</li>
<li>You can select single repository group or summary for all of them.</li>
<li>We are showing top 255 most active companies in the drop-down list.</li>
<li>Selecting period (for example week) means that dashboard will show statistics in those periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
<li>We are skipping bots when calculating statistics, see <a href="https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md" target="_blank">excluding bots</a> for details.</li>
<li>We are determining user's company affiliation from <a href="https://github.com/cncf/devstats/blob/master/github_users.json" target="_blank">this file</a>, which is imported from <code>cncf/gitdm</code>.</li>
</ul>
