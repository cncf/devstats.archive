<h1 id="dashboard-header">[[full_name]] user reviews dashboard</h1>
<p>Links:</p>
<ul>
<li>Metric <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/reviews_per_user.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/metrics.yaml" target="_blank">series definition</a>. Search for <code>reviews_per_user</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/[[lower_name]]/user-reviews.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows number of PR reviews most active reviewers.</li>
<li>Review means user added PR review comment.</li>
<li>You can select reviewer from the reviewers drop-down, it shows top active reviewers from last 3 months.</li>
<li>To find top active reviewers we sum number of reviews per user.</li>
<li>You can select single repository or summary for all of them.</li>
<li>You can filter by period and choose multiple reviewers to stack their data.</li>
<li>Selecting period (for example week) means that dashboard will show reviews in those periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
</ul>
