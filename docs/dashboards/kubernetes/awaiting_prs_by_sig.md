<h1 id="kubernetes-dashboard">[[full_name]] Awaiting PRs by SIG dashboard</h1>
<p>Links:</p>
<ul>
<li>Metric <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/awaiting_prs_by_sig.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml" target="_blank">series definition</a>. Search for <code>awaiting_prs_by_sig</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/awaiting-prs-by-sig.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows the number of PRs opened by SIG that were open for longer than 10, 30, 60, 90 days and 1 year.</li>
<li>We're counting PRs that were opened more than specified amount of time at given point in time, so for example data for 1 month ago show PRs that were open for more than 10 days 1 month ago (now they may be open for 2 months or merged already).</li>
<li>PR belongs to SIG by using <code>sig/*</code> labels. List of SIGs to display in drop-down comes from all <code>sig/*</code> labels.</li>
</ul>
