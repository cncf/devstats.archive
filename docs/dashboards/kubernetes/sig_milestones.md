<h1 id="kubernetes-dashboard">Kubernetes open issues/PRs by milestone and repository dashboard</h1>
<p>Links:</p>
<ul>
<li>Open issues metric <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/open_issues_sigs_milestones.sql" target="_blank">SQL file</a>.</li>
<li>Open PRs metric <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/open_prs_sigs_milestones.sql" target="_blank">SQL file</a>.</li>
<li>TSDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml" target="_blank">series definition</a>. Search for <code>sigs_milestones</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/open-issues-prs-by-milestone-and-repository.json" target="_blank">JSON</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>Dashboard shows number of open issues and PRs for given SIG and milestone.</li>
<li>It shows number of issues/PRs that were open at given point in time.</li>
<li>It detects issue/PR SIG by <code>sig/*</code> labels. You can also select all SIGs.</li>
<li>You can filter by specific milestone or select all milestones.</li>
<li>You can filter by specific repository or select all repositories.</li>
<li>Milestone and labels set is determined from last issue/PR comment before or at given point in time.</li>
<li>We're using special dedicated tool that uses GitHub API to get newest issue/PR state because labels/milestones are usually updated by k8s-bot after the comment (in reaction to comment's command).</li>
</ul>
