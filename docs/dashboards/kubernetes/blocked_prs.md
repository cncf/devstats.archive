<h1 id="kubernetes-dashboard">[[full_name]] Blocked PRs by repository group dashboard</h1>
<p>Links:</p>
<ul>
<li>Metric <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/prs_blocked.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml" target="_blank">series definition</a>. Search for <code>prs_blocked</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/blocked-prs-repository-groups.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows number of PRs that were blocked due to various reasons at given point of time.</li>
<li>It shows PRs that were created during the selected periods.</li>
<li>Chart shows number of all PRs and PRs blocked due to missing: <code>approved</code> or <code>lgtm</code> labels.</li>
<li>It also list PRs blocked due to <code>release-note-label-needed</code> or <code>needs-ok-to-test</code> or <code>do-not-merge*</code> labels.</li>
<li>You can select single repository group or summary for all of them.</li>
<li>Selecting period (for example week) means that dashboard will show PRs blocked in those periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
</ul>
