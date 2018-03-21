<h1 id="kubernetes-sig-mentions-categories-dashboard">Kubernetes SIG mentions categories dashboard</h1>
<p>Links:</p>
<ul>
<li>First panel Postgres <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/sig_mentions_cats.sql" target="_blank">SQL file</a>.</li>
<li>Second panel Postgres <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/sig_mentions_breakdown.sql" target="_blank">SQL file</a>.</li>
<li>InfluxDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml" target="_blank">series definition</a>. Search for <code>sig_mentions_cats</code> and <code>sig_mentions_breakdown</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_categories.json" target="_blank">JSON</a>.</li>
<li>Developer <a href="https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions_cats_devel.md" target="_blank">documentation</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows stacked number of various SIG categories mentions.</li>
<li>It shows stacked chart of each category mentions for all SIGs in one panel and stacked chart of each category mentions for a SIG selected from the drop down in another panel.</li>
<li>First panel uses first Postgres query, second panel uses second query.</li>
<li>There are following categories defined: <strong>bug, feature-request, pr-review, api-review, misc, proposal, design-proposal, test-failure</strong></li>
<li>We are getting SIG mentions from all <strong>texts</strong>.</li>
<li>To find a SIG we&#39;re looking for texts like this <code>@kubernetes/sig-SIG-category</code>.</li>
<li>For example <code>@kubernetes/sig-cluster-lifecycle-pr-review</code> will evaluate SIG to <code>cluster-lifecycle</code> and category to <code>pr-review</code>.</li>
<li>There can be other texts before and after the SIG, so <code>Hi there @kubernetes/sig-apps-feature-request, I want to ...</code> will evaluate to SIG: <code>apps</code>, category: <code>feature-request</code>.</li>
<li>For exact <code>regexp</code> used, please check developer <a href="https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions_cats_devel.md" target="_blank">documentation</a>.</li>
<li><strong>Texts</strong> means comments, commit messages, issue titles, issue texts, PR titles, PR texts, PR review texts.</li>
<li>You can filter by SIG and categories. You must select one SIG to display its categories stacked on the second panel. First panel aggregates category data for all SIGs.</li>
<li>You can select multiple categories to display, or select special value <em>All</em> to display all categories.</li>
<li>Selecting period (for example week) means that dahsboard will count SIG mentions in these periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
<li>We&#39;re also excluding bots activity, see <a href="https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md" target="_blank">excluding bots</a>.</li>
</ul>

