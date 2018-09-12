<h1 id="dashboard-header">[[full_name]] gender stats dashboard</h1>
<p>Links:</p>
<ul>
<li>Metric <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/gender.sql" target="_blank">SQL file</a>.</li>
<li>Cumulative metric <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/gender_cum.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/metrics.yaml" target="_blank">series definition</a>. Search for <code>gender</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/[[lower_name]]/gender-stats.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows contributor gender statistics (cumulative and in given periods).</li>
<li>Contributor is defined as somebody who made a review, comment, commit, created PR or issue.</li>
<li>Contribution is a review, comment, commit, issue or PR.</li>
<li>We are determining contributor's gender by using GitHub localization and user name to query <a href="https://store.genderize.io" target="_blank">genderize.io</a> for gender for a given country and name.</li>
<li>You can select single repository group or summary statistics for all of them combined.</li>
<li>You can choose to display contributors, contributions, users or actvity.</li>
<li>You can select cumulative statistics or statistics in given periods.</li>
<li>Selecting period (for example week) means that dashboard will show data in those periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
<li>We are skipping bots activity, see <a href="https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md" target="_blank">excluding bots</a> for details.</li>
</ul>
