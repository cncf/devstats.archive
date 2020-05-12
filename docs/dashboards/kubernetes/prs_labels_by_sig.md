<h1 id="kubernetes-dashboard">[[full_name]] PR labels by SIG dashboard</h1>
<p>Links:</p>
<ul>
<li>Metric <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/prs_labels_by_sig.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml" target="_blank">series definition</a>. Search for <code>prs_labelsi_by_sig</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/prs-labels-by-sig.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard how many PRs opened by a given SIG have/had a specified label(s) at given point in time.</li>
<li>List of labels is hardcoded. It contains PR merge blocker labels.</li>
<li>You can select any of labels from given set or choose <code>All labels combined</code>.</li>
<li>You can select single SIG or summary for all of them <code>All SIGs combined</code>.</li>
<li>There are multiple charts that show summaries for all SIGs and/or for all labels.</li>
<li>PR belongs to SIG by using <code>sig/*</code> labels. List of SIGs to display in drop-down comes from all <code>sig/*</code> labels.</li>
</ul>
