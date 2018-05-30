<h1 id="kubernetes-dashboard">[[full_name]] PRs approval repository groups dashboard</h1>
<p>Links:</p>
<ul>
<li>Metric <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/prs_state.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml" target="_blank">series definition</a>. Search for <code>prs_state</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/prs-approval-repository-groups.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows number of approved and awaiting approval non-closed PRs modifed in given periods.</li>
<li>Non-closed PR is a PR that is either open or merged.</li>
<li>Approved PR is a PR that is either merged or open and have <code>approved</code> or <code>lgtm</code> label.</li>
<li>You can select single repository group or summary for all of them.</li>
<li>Selecting period (for example week) means that dashboard will show data for PRs modified in those periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
</ul>
