<h1 id="kubernetes-sig-mentions-labels-dashboard">Kubernetes SIG mentions using labels dashboard</h1>
<p>Links:</p>
<ul>
<li>First panel Postgres <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_sig_kind.sql" target="_blank">SQL file</a>.</li>
<li>Second panel Postgres <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_kind.sql" target="_blank">SQL file</a>.</li>
<li>Third panel Postgres <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_sig.sql" target="_blank">SQL file</a>.</li>
<li>InfluxDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml" target="_blank">series definition</a>. Search for <code>labels_sig_kind</code>, <code>labels_sig</code> and <code>labels_kind</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_using_labels.json" target="_blank">JSON</a>.</li>
<li>Developer <a href="https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions_labels_devel.md" target="_blank">documentation</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows stacked number of issues that belongs to given SIGs and categories/kinds (by using issue labels)</li>
<li>First panel shows stacked chart of number of issues belonging to selected categories for a selected SIG. It stacks different categories/kinds. It uses first SQL.</li>
<li>Second panel shows stacked chart of number of issues belonging to selected categories (no matter which SIG, even no SIG at all). It stacks different categories/kinds. It uses second SQL.</li>
<li>Third panel shows stacked chart of number of issues belonging to a given SIGs. It stacks by SIG and displays all possible SIGs found. It uses third SQL.</li>
<li>To mark issue as belonging to some `SIGNAME` SIG - it must have `sig/SIGNAME` label.</li>
<li>To mark issue as belonging to some `CAT` category/kind - it must have `kind/CAT` label.</li>
<li>SIG list comes from all possible values of `SIG/sig` labels, category list contains all possible values of `kind/kind` labels.</li>
<li>You can filter by SIG and categories.</li>
<li>You must select exactly one SIG.</li>
<li>You can select multiple categories to display, or select special value <em>All</em> to display all categories.</li>
<li>Selecting period (for example week) means that dahsboard will count issues in these periods. 7 Day MA will count issues in 7 day window and divide result by 7 (so it will be 7 days MA value)</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
</ul>

