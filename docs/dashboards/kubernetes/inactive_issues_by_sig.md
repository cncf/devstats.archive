<h1 id="kubernetes-dashboard">[[full_name]] Inactive issues by SIG (and repository) dashboard</h1>
<p>Links:</p>
<ul>
<li>Metric <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/inactive_issues_by_sig.sql" target="_blank">SQL file</a>.</li>
<li>Metric (repositories version) <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/inactive_issues_by_sig_repos.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml" target="_blank">series definition</a>. Search for <code>inactive_issues_by_sig(_repos)</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/inactive-issues-by-sig.json" target="_blank">JSON</a>.</li>
<li>Grafana dashboard (repositories version) <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/inactive-issues-by-sig-and-repository.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows the number of issues opened by SIG that were inactive for longer than 14, 30 and 90 days.</li>
<li>Inactive means issues that are open and have no activity other than author and bots more than specified amount of time at given point in time, so for example data for 2 weeks ago show issues that were inactive for more than 14 days 2 weeks ago (now they may be inactive for 1 month or some activity happened earlier than 14 days ago).</li>
<li>Issues belongs to SIG by using <code>sig/*</code> labels. List of SIGs to display in drop-down comes from all <code>sig/*</code> labels.</li>
<li>In repositories version you can select repository to per single repository statistics. Note that not all SIGs may be present in may repos, so you need to select a sub-set or a single one from SIG drop down.</li>
</ul>
