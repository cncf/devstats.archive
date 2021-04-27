<h1 id="kubernetes-dashboard">[[full_name]] Contributions chart dashboard</h1>
<p>Links:</p>
<ul>
<li>Reviewers metric (repo groups) <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/reviewers.sql" target="_blank">SQL file</a>.</li>
<li>Approvers metric (repo groups) <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/approvers.sql" target="_blank">SQL file</a>.</li>
<li>Committers metric (repo groups) <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/committers.sql" target="_blank">SQL file</a>.</li>
<li>Contributors metric (repo groups) <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/contributors.sql" target="_blank">SQL file</a>.</li>
<li>Reviewers metric (repositories) <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/reviewers_repos.sql" target="_blank">SQL file</a>.</li>
<li>Approvers metric (repositories) <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/approvers_repos.sql" target="_blank">SQL file</a>.</li>
<li>Committers metric (repositories) <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/committers_repos.sql" target="_blank">SQL file</a>.</li>
<li>Contributors metric (repositories) <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/contributors_repos.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml" target="_blank">series definition</a>. Search for <code>Contributions chart</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/contributions-chart.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows various developer metrics groupped by repository groups, counteries and companies.</li>
<li>Approve is defined when someone adds <code>/approve</code> comment.</li>
<li>Review is defined when someone adds <code>/approve</code> or <code>/lgtm</code> comment or adds <code>approved</code> or <code>lgtm</code> label or adds PR review comment.</li>
<li>You can select last day, month, week or 7 days moving average.</li>
<li>If you select moving average, you will see the number of contributors in a moving 7 day average window and the number of contributions in that window divided by 7.</li>
<li>You can select repository group or summary for all of them (for the top panel).</li>
<li>You can select repository for bottom panel showing per single repository statistics.</li>
<li>You can select country from a drop-down or summary for all countries.</li>
<li>You can select company from a drop-down or summary for all companies.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
<li>We are skipping bots when calculating statistics, see <a href="https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md" target="_blank">excluding bots</a> for details.</li>
<li>We are determining user's company affiliation from <a href="https://github.com/cncf/devstats/blob/master/github_users.json" target="_blank">this file</a>, which is imported from <code>cncf/gitdm</code>.</li>
</ul>
