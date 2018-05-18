<h1 id="kubernetes-sig-mentions-dashboard">Kubernetes SIG mentions dashboard</h1>
<p>Links:</p>
<ul>
<li>Postgres <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/sig_mentions.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml#L246-L252" target="_blank">series definition</a>.</li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions.json" target="_blank">JSON</a>.</li>
<li>Developer <a href="https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions_devel.md" target="_blank">documentation</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows stacked number of various SIG mentions.</li>
<li>We are getting SIG from all <strong>texts</strong>.</li>
<li>To find a SIG we&#39;re looking for texts like this <code>@kubernetes/sig-SIG-kind</code>, where kind can be: <em>bug, feature-request, pr-review, api-review, misc, proposal, design-proposal, test-failure</em>.</li>
<li>For example <code>@kubernetes/sig-cluster-lifecycle-pr-review</code> will evaluate to <code>cluster-lifecycle</code>.</li>
<li>Kind part is optional, so <code>@kubernetes/sig-node</code> will evaluate to <code>node</code>.</li>
<li>There can be other texts before and after the SIG, so <code>Hi there @kubernetes/sig-apps-feature-request, I want to ...</code> will evaluate to <code>apps</code>.</li>
<li>For exact <code>regexp</code> used, please check developer <a href="https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions_devel.md" target="_blank">documentation</a>.</li>
<li><strong>Texts</strong> means comments, commit messages, issue titles, issue texts, PR titles, PR texts, PR review texts.</li>
<li>You can filter by period and SIG(s).</li>
<li>Selecting period (for example week) means that dahsboard will count SIG mentions in these periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
<li>This dashboard allows to select multiple SIG, it contains special &#39;All&#39; value to display all SIGs.</li>
<li>We&#39;re also excluding bots activity, see <a href="https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md" target="_blank">excluding bots</a>.</li>
</ul>

