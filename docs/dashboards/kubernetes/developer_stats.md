<h1 id="kubernetes-dashboard">[[full_name]] Developer Activity Counts by Repository Group dashboard</h1>
<p>Links:</p>
<ul>
<li>Main metric <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/project_developer_stats.sql" target="_blank">SQL file</a>.</li>
<li>Approvers metric <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/hist_approvers.sql" target="_blank">SQL file</a>.</li>
<li>Reviewers metric <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/hist_reviewers.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml" target="_blank">series definition</a>. Search for <code>Developer activity</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/developer-activity-counts-by-repository-group.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows various developer metrics.</li>
<li>Approve is defined when someone adds <code>/approve</code> comment.</li>
<li>Review is defined when someone adds <code>/approve</code> or <code>/lgtm</code> comment, or adds <code>approved</code> or <code>lgtm</code> label or adds PR review comment.</li>
<li>You can select last day, month, week etc. range or date range between releases, for example <code>v1.9 - v1.10</code>.</li>
<li>You can select single repository group or summary for all of them.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
<li>We are skipping bots when calculating statistics, see <a href="https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md" target="_blank">excluding bots</a> for details.</li>
<li>We are determining user's company affiliation from <a href="https://github.com/cncf/devstats/blob/master/github_users.json" target="_blank">this file</a>, which is imported from <code>cncf/gitdm</code>.</li>
</ul>
