<h1>[[full_name]] Contributions chart dashboard</h1>
<p>Links:</p>
<ul>
<li>Committers metric <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/committers.sql" target="_blank">SQL file</a>.</li>
<li>Contributors metric <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/contributors.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/[[lower_name]]/metrics.yaml" target="_blank">series definition</a>. Search for <code>Contributions chart</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/[[lower_name]]/contributions-chart.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows various developer metrics groupped by repository groups, counteries and companies.</li>
<li>You can select last day, month, week or 7 days moving average.</li>
<li>If you select moving average, you will see the number of contributors in a moving 7 day average window and the number of contributions in that window divided by 7.</li>
<li>You can select repository group or summary for all of them.</li>
<li>You can select country from a drop-down or summary for all countries.</li>
<li>You can select company from a drop-down or summary for all companies.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
<li>We are skipping bots when calculating statistics, see <a href="https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md" target="_blank">excluding bots</a> for details.</li>
<li>We are determining user's company affiliation from <a href="https://github.com/cncf/devstats/blob/master/github_users.json" target="_blank">this file</a>, which is imported from <code>cncf/gitdm</code>.</li>
</ul>
