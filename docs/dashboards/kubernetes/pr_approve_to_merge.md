<h1 id="kubernetes-dashboard">[[full_name]] PR Time to Approve and Merge dashboard</h1>
<p>Links:</p>
<ul>
<li>Metric <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/time_metrics.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml" target="_blank">series definition</a>. Search for <code>time_metrics</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/pr-time-to-approve-and-merge.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard show median and 85th percentile time for merged PRs from open to LGTM, approve and merge.</li>
<li>LGTM happens when <code>lgtm</code> label is added on a PR.</li>
<li>Approve happens when <code>approved</code> label is added on a PR.</li>
<li>Open to LGTM time is defined as time from open to LGTM when LGTM is present or from open to approve when approve is present or from open to merge if neither lgtm nor approve is present.</li>
<li>It means that adding approved label when there is no lgtm label means LGTM too. Merging PR without approve or lgtm labels also means LGTM.</li>
<li>LGTM to approve is defined as time from LGTM to approve when approve is present or from lgtm to merge if there is no approved label. If there is no LGTM this is zero.</li>
<li>It means that merging PR means approving it.</li>
<li>Approve to merge is defined as time from approve to merge if approved label is present. It is zero otherwise.</li>
<li>You can filter by PR size. PR size is defined by <code>size/*</code> label. You can select All to get all PRs.</li>
<li>You can select PRs with a specific <code>kind/*</code> label or summary for all of them.</li>
<li>You can filter by API change. PR belongs to API change yes when it has <code>kind/api-change</code> label. You can select All to get all PRs.</li>
<li>You can select single repository group or summary for all of them.</li>
<li>Selecting period (for example week) means that dashboard will data for PRs created in those periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
</ul>
