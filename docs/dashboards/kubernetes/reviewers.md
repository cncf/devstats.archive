<h1 id="kubernetes-reviewers-dashboard">Kubernetes reviewers dashboard (part of GitHub stats dashboard)</h1>
<p>Links:</p>
<ul>
<li>Repository groups version metric <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/github_stats_by_repo_groups.sql" target="_blank">SQL file</a>.</li>
<li>Repositories version metric <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/github_stats_by_repos.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml" target="_blank">series definition</a>. Search for <code>github_stats_by_repo</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/github-stats-by-repository-group.json" target="_blank">JSON</a> (repository groups version).</li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/github-stats-by-repository.json" target="_blank">JSON</a> (repositories version).</li>
<li>Developer <a href="https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/reviewers_devel.md" target="_blank">documentation</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This documentations only refers to <code>Reviewers</code> statistic.
<li>This dashboard shows the number of reviewers for a selected repository or repository group.</li>
<li>You can select multiple repositories or repository groups to stack them.</li>
<li>Reviewer is defined as someone who added pull request review comment(s) or added <code>/lgtm</code> or <code>/approve</code> text or added <code>lgtm</code> or <code>approve</code> label.</li>
<li>You can filter by repository or repository group and period.</li>
<li>Selecting period (for example week) means that dahsboard will count distinct users who made a review in these periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
<li>We are skipping bots when calculating number of reviewers, see <a href="https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md" target="_blank">excluding bots</a> for details.</li>
</ul>

