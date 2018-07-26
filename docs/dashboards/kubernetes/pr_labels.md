<h1 id="kubernetes-dashboard">[[full_name]] PR labels repository groups dashboard</h1>
<p>Links:</p>
<ul>
<li>Metric <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/prs_labels.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml" target="_blank">series definition</a>. Search for <code>prs_labels</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/prs-labels-repository-groups.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard how many PRs have/had a specified label(s) in a given repository group(s) at given point in time.</li>
<li>List of labels is hardcoded. It contains PR merge blocker labels.</li>
<li>You can select any of labels from given set or choose <code>All labels combined</code>.</li>
<li>You can select single repository group or summary for all of them <code>All repos combined</code>.</li>
<li>There are multiple charts that show summaries for all repo groups and/or for all labels.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
</ul>
