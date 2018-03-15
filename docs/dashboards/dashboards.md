<h1 id="-full_name-home-dashboard">[[full_name]] Home dashboard</h1>
<p>Links:</p>
<ul>
<li>Postgres <a href="https://github.com/cncf/devstats/blob/master/metrics/[[proj_name]]/events.sql">SQL file</a>.</li>
<li>InfluxDB <a href="https://github.com/cncf/devstats/blob/master/metrics/[[proj_name]]/metrics.yaml">series definition</a> (search for <code>name: GitHub activity</code>).</li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/[[proj_name]]/dashboards.json">JSON</a>.</li>
<li>Developer <a href="https://github.com/cncf/devstats/blob/master/docs/dashboards/dashboards_devel.md">documentation</a>.</li>
<li>Direct <a href="https://k8s.[[hostname]]/d/12/dashboards?refresh=15m&amp;orgId=1">link</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>First we&#39;re displaying links to all CNCF projects defined.</li>
<li>Next we&#39;re showing current project&#39;s hourly activity - this is the number of all GitHub events that happened for [[full_name]] project hourly.</li>
<li>This also includes bots activity (most other dashboards skip bot activity).</li>
<li>Next we&#39;re showing HTML panel that shows all CNCF projects icons and links.</li>
<li>Next there is a dashboard that shows a list of all dashboards defined for [[full_name]] project.</li>
</ul>

