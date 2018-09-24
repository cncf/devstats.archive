<h1 id="dashboard-header">[[full_name]] time zones stats dashboard</h1>
<p>Links:</p>
<ul>
<li>1st metric <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/tz.sql" target="_blank">SQL file</a>.</li>
<li>2nd metric <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/committers_tz.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/metrics.yaml" target="_blank">series definition</a>. Search for <code>tz</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/[[lower_name]]/timezones-stats.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows timezones statistics.</li>
<li>We're showing histograms over time (called heatmap), color is used to show higher/lower counts for given TZ offsets and dates.</li>
<li>Contributor is defined as somebody who made a review, comment, commit, created PR or issue.</li>
<li>Contribution is a review, comment, commit, issue or PR.</li>
<li>We are determining contributor's timezone by using GitHub localization and searching for a timezone using <a href="http://www.geonames.org" target="_blank">geonames</a> database.</li>
<li>You can select single repository group or summary statistics for all of them combined.</li>
<li>You can choose to display contributors, contributions, users, actvity, committers, commits etc.</li>
<li>Selecting period (for example week) means that dashboard will show data in those periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
<li>We are skipping bots activity, see <a href="https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md" target="_blank">excluding bots</a> for details.</li>
</ul>
