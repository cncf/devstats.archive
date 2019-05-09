<h1 id="dashboard-header">[[full_name]] company commits table dashboard</h1>
<p>Links:</p>
<ul>
<li>Company commits metric <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/company_commits_data.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/metrics.yaml" target="_blank">series definition</a>. Search for <code>Company commits table</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/[[lower_name]]/company-commits-table.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows statistics about company commits.</li>
<li>You can select date range to show company commits for this period.</li>
<li>You can select multiple repository groups or all of them in a multi select dowp down.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
<li>You can select multiple companies or all of them in a multi select dowp down.</li>
<li>We are showing top 255 most active companies in the drop-down list.</li>
<li>We are skipping bots activity, see <a href="https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md" target="_blank">excluding bots</a> for details.</li>
<li>We are determining user's company affiliation from <a href="https://github.com/cncf/devstats/blob/master/github_users.json" target="_blank">this file</a>, which is imported from <code>cncf/gitdm</code>.</li>
</ul>
