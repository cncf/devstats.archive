<h1 id="-full_name-home-dashboard">[[full_name]] last updated dashboard</h1>
<p>Links:</p>
<ul>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/[[proj_name]]/last-updated.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>&#39;Metric name&#39; maps to a specific SQL file name (without <code>.sql</code> extension) used in a given dashboard, for example &#39;events&#39; maps to <a href="https://github.com/cncf/devstats/blob/master/metrics/shared/events.sql" target="_blank">events.sql</a>.</li>
<li>Each dashboard has a list of metrics used in its dashboard documentation panel.</li>
<li>Then there is a time period marker like <code>d, d7, h, h24, w, m, q, y, y10, a_x_y, a_x_n, c_b, c_n, c_j_i, c_i_g, c_i_n, c_j_g, c_g_n, </code> they mean:</li>
<li>h - hourly, hN - moving average of N hours, d - daily, dN - moving average of N days, w - week, m - month, q - quarter, y - year, each can have extra N, examples: h24, d7, m3, y10.</li>
<li><code>a_x_y</code> - between annotations, <code>a_0_1</code> - between 1st and 2nd annotaion and so on, <code>a_x_n</code> - when (x+1)th annotation is the last one then it is from (n+1)th annotation till now. Examples: <code>a_10_11, a_11_n</code>.</li>
<li><code>c_n</code> - from joining CNCF till now, <code>c_b</code> - from beginning till joining CNCF.</li>
<li><code>c_j_i, c_j_g</code> - since joining CNCF till incubation (<code>c_j_i</code>), graduation (<code>c_j_g</code>).</li>
<li><code>c_i_g</code> - since incubation to graduation, <code>c_i_n</code> - since incubation to now, <code>c_g_n</code> - since graduation to now.</li>
</ul>
