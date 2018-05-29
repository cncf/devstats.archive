<h1 id="kubernetes-dashboard">[[full_name]] New And Episodic PR Contributors dashboard</h1>
<p>Links:</p>
<ul>
<li>New PRs metric <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/new_contributors.sql" target="_blank">SQL file</a>.</li>
<li>Episodic PRs metric <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/episodic_contributors.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml" target="_blank">series definition</a>. Search for <code>New and episodic PR</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/new-and-episodic-pr-contributors.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows statistics about new and episodic PRs and contributors (PR creators).</li>
<li>New contributor (PR creator) is someone who haven't created any PR before given period.</li>
<li>New PR is a PR created by new contributor</li>
<li>Episodic contributor (PR creator) is someone who haven't created any PR in 3 months before given project and haven't created more than 12 PRs overall.</li>
<li>Episodic PR is a PR created by episodic contributor.</li>
<li>You can select single repository group or summary for all of them.</li>
<li>Selecting period (for example week) means that dashboard will calculate statistics in those periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
</ul>
