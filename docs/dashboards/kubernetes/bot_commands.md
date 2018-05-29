<h1 id="kubernetes-dashboard">[[full_name]] Bot commands repository group dashboard</h1>
<p>Links:</p>
<ul>
<li>Metric <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/bot_commands.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml" target="_blank">series definition</a>. Search for <code>bot_commands</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/bot-commands-repository-groups.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows how many times given bot commands were used.</li>
<li>Bot commands set is defined (hardcoded) in the metric sql, they start with <code>/</code>.</li>
<li>Drop-down commands values come from <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/bot_commands_tags.sql" target="_blank">this</a> file. You can select either all or a subset of all commands to display.</li>
<li>You can select single repository group or summary for all of them.</li>
<li>Selecting period (for example week) means that dashboard will show bot commands used in those periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
<li>We are skipping bots when displaying bots commands usage, see <a href="https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md" target="_blank">excluding bots</a> for details.</li>
<li>This means that, for example, if somebody uses wrong/non-existing bot command, bot will answer with correct usage, so it will put bot command in the comment. This activity is ignored.</li>
</ul>
