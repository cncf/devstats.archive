<h1 id="dashboard-header">[[full_name]] new and episodic issue creators dashboard</h1>
<p>Links:</p>
<ul>
<li>New issues metric <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/new_issues.sql" target="_blank">SQL file</a>.</li>
<li>Episodic issues metric <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/episodic_issues.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/metrics.yaml" target="_blank">series definition</a>. Search for <code>New and episodic issues</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/[[lower_name]]/new-and-episodic-issue-creators.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows statistics about new and episodic issues and issue creators.</li>
<li>New issue creator is someone who haven't created any issue before given period.</li>
<li>New issue is an issue created by new issue creator</li>
<li>Episodic issue creator is someone who haven't created any issue in 3 months before given project and haven't created more than 12 issues overall.</li>
<li>Episodic issue is an issue created by episodic issue creator.</li>
<li>You can select single repository group or summary for all of them.</li>
<li>Selecting period (for example week) means that dashboard will calculate statistics in those periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
</ul>
