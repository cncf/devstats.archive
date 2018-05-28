<h1 id="kubernetes-dashboard">[[full_name]] Companies table dashboard</h1>
<p>Links:</p>
<ul>
<li>Chart version metric <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/pr_workload.sql" target="_blank">SQL file</a>.</li>
<li>Table version metric <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/pr_workload_table.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml" target="_blank">series definition</a>. Search for <code>pr_workload</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/pr-workload-per-sig-chart.json" target="_blank">JSON</a> (chart version).</li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/pr-workload-per-sig-table.json" target="_blank">JSON</a> (table version).</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>Those dashboards show PR workload for SIGs</li>
<li>Chart version allows to see absolute and relative PR worklod as line charts, stacked charts and stacked percent charts.</li>
<li>Chart version also allows to see chart of SIG PRs and SIG reviewers. You can select list of SIGs to display.</li>
<li>Table version allows to see absolute and relative PR workload per SIG and number of PRs and reviewers for given SIGs.</li>
<li>Table version also allows to choose period to display metric, like last month, year, particular release etc.</li>
<li>For chart version we're counting PRs that were opened at given point in time (not closed, not merged).</li>
<li>For table version we're counting PRs taht were open at the period's end (for last week it is now), for v1.9 - v1.10 it is v1.10</li>
<li>PR size comes from <code>size/*</code> labels. Different sizes, have different weights.</li>
<li>xs: 0.25, small, s: 0.5, large, l: 2, xl: 4, xxl: 8. All other size labels (or no size label) have weight 1.</li>
<li>PR belongs to SIG by using <code>sig/*</code> labels. List of SIGs to display in drop-down comes from all <code>sig/*</code> labels.</li>
<li>Absolute PR workload is a weighted sum of all PRs for a given SIG using size labels as weights.</li>
<li>Relative PR workload for given SIG is absolute PR workload divided by number of reviewers for given SIG.</li>
<li>Number of reviewers is calculated in last month preceeding given point in time for chart version.</li>
<li>For table version we're conting reviewers in a selected period.</li>
<li>Reviewer is somebody who added <code>/lgtm</code> or <code>/approve</code> text or <code>lgtm</code> or <code>approve</code> label.</li>
<li>We are skipping bots when calculating statistics, see <a href="https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md" target="_blank">excluding bots</a> for details.</li>
</ul>

