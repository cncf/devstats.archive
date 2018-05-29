<h1 id="kubernetes-dashboard">[[full_name]] Issues Opened/Closed by SIG dashboard</h1>
<p>Links:</p>
<ul>
<li>Opened issues metric <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_sig_kind.sql" target="_blank">SQL file</a>.</li>
<li>Closed issues metric <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_sig_kind_closed.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml" target="_blank">series definition</a>. Search for <code>Issues opened</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/issues-opened-closed-by-sig.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows the chart of how many issues were opened and closed in selected periods.</li>
<li>You can filter by SIG and kind.</li>
<li>Issue SIG is determined by <code>sig/*</code> labels. You can also select summary for all issues by choosing <code>All</code> SIG.</li>
<li>Issue kind is determined by <code>kind/*</code> labels. You can also select summary for all issues by choosing <code>All</code> kind.</li>
<li>Selecting period (for example week) means that dashboard will show number of issues in those periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
</ul>
