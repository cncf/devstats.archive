<h1 id="dashboard-header">[[full_name]] PRs merged repository groups dashboard</h1>
<p>Links:</p>
<ul>
<li>Metric <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/prs_merged_groups.sql" target="_blank">SQL file</a> (repo groups).</li>
<li>Metric <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/all_prs_merged.sql" target="_blank">SQL file</a> (all PRs merged).</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/metrics.yaml" target="_blank">series definition</a>. Search for <code>prs_merged_groups</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/[[lower_name]]/prs-merged-repository-groups.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows number of PRs merged in given periods in selected repository groups.</li>
<li>One panel shows stacked number of PRs merged in selected repositories. Second panel shows chart for all PRs merged in all repository groups.</li>
<li>Selecting period (for example week) means that dashboard will show PRs merged in those periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
<li>We are skipping bots activity, see <a href="https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md" target="_blank">excluding bots</a> for details.</li>
</ul>
