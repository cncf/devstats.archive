# Grafana dashboards

This is a list of dashboards for Kubernetes project only:

Each dashboard is defined by its metrics SQL, saved Grafana JSON export and link to dashboard running on <https://k8s.devstats.cncf.io>  

Many dashboards use "Repository group" drop-down. Repository groups are defined manually to group similar repositories into single projects.
They are defined here: [repo_groups.sql](https://github.com/cncf/devstats/blob/master/scripts/kubernetes/repo_groups.sql)

# Import and export

- To get all currently defined dashboard from their Grafana's SQLite databases use: `./devel/get_all_sqlite_jsons.sh`.
- To put all JSONs into their Grafana's SQLite databases use: `./devel/put_all_charts.sh`. If all is OK, clean DB backups: `./devel/put_all_charts_cleanup.sh`.
- To specify a list of projects to import/export prepend commands with: `ONLY="project1 project2 ... projectN"`.
- See [this](https://github.com/cncf/devstats/blob/master/SQLITE.md) file for more details.

# Kubernetes dashboards

- Blocked PRs repository groups: [blocked-prs-repository-groups.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/blocked-prs-repository-groups.json), [view](https://k8s.devstats.cncf.io/d/4/blocked-prs-repository-groups?orgId=1)
- Bot commands repository groups: [bot-commands-repository-groups.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/bot-commands-repository-groups.json), [view](https://k8s.devstats.cncf.io/d/5/bot-commands-repository-groups?orgId=1)
- Companies contributing in repository groups: [companies-contributing-in-repository-groups.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/companies-contributing-in-repository-groups.json), [view](https://k8s.devstats.cncf.io/d/11/companies-contributing-in-repository-groups?orgId=1)
- Companies table: [companies-table.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/companies-table.json), [view](https://k8s.devstats.cncf.io/d/9/companies-table?orgId=1)
- Company Statistics by Repository Group: [company-statistics-by-repository-group.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/company-statistics-by-repository-group.json), [view](https://k8s.devstats.cncf.io/d/8/company-statistics-by-repository-group?orgId=1)
- Dashboards: [dashboards.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json), [view](https://k8s.devstats.cncf.io/d/12/dashboards?orgId=1)
- Developer Activity Counts by Repository Group: [developer-activity-counts-by-repository-group.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/developer-activity-counts-by-repository-group.json), [view](https://k8s.devstats.cncf.io/d/13/developer-activity-counts-by-repository-group?orgId=1)
- Github Stats by Repository: [github-stats-by-repository.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/github-stats-by-repository.json), [view](https://k8s.devstats.cncf.io/d/49/github-stats-by-repository?orgId=1)
- Github Stats by Repository Group: [github-stats-by-repository-group.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/github-stats-by-repository-group.json), [view](https://k8s.devstats.cncf.io/d/48/github-stats-by-repository-group?orgId=1)
- Issues Opened/Closed by SIG: [issues-opened-closed-by-sig.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/issues-opened-closed-by-sig.json), [view](https://k8s.devstats.cncf.io/d/39/issues-opened-closed-by-sig?orgId=1)
- Issues age by SIG and repository groups: [issues-age-by-sig-and-repository-groups.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/issues-age-by-sig-and-repository-groups.json), [view](https://k8s.devstats.cncf.io/d/15/issues-age-by-sig-and-repository-groups?orgId=1)
- New And Episodic Issue Creators: [new-and-episodic-issue-creators.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/new-and-episodic-issue-creators.json), [view](https://k8s.devstats.cncf.io/d/19/new-and-episodic-issue-creators?orgId=1)
- New and Episodic PR Contributors: [new-and-episodic-pr-contributors.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/new-and-episodic-pr-contributors.json), [view](https://k8s.devstats.cncf.io/d/18/new-and-episodic-pr-contributors?orgId=1)
- Open PR Age By Repository Group: [open-pr-age-by-repository-group.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/open-pr-age-by-repository-group.json), [view](https://k8s.devstats.cncf.io/d/25/open-pr-age-by-repository-group?orgId=1)
- Open issues/PRs by milestone and repository: [open-issues-prs-by-milestone-and-repository.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/open-issues-prs-by-milestone-and-repository.json), [view](https://k8s.devstats.cncf.io/d/22/open-issues-prs-by-milestone-and-repository?orgId=1)
- Overall Project Statistics: [overall-project-statistics.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/overall-project-statistics.json), [view](https://k8s.devstats.cncf.io/d/24/overall-project-statistics?orgId=1)
- PR Reviews by Contributor: [pr-reviews-by-contributor.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/pr-reviews-by-contributor.json), [view](https://k8s.devstats.cncf.io/d/46/pr-reviews-by-contributor?orgId=1)
- PR Time to Engagment: [pr-time-to-engagment.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/pr-time-to-engagment.json), [view](https://k8s.devstats.cncf.io/d/14/pr-time-to-engagment?orgId=1)
- PR Time to merge: [pr-time-to-merge.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/pr-time-to-merge.json), [view](https://k8s.devstats.cncf.io/d/21/pr-time-to-merge?orgId=1)
- PR Workload per SIG Chart: [pr-workload-per-sig-chart.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/pr-workload-per-sig-chart.json), [view](https://k8s.devstats.cncf.io/d/33/pr-workload-per-sig-chart?orgId=1)
- PR Workload per SIG Table: [pr-workload-per-sig-table.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/pr-workload-per-sig-table.json), [view](https://k8s.devstats.cncf.io/d/34/pr-workload-per-sig-table?orgId=1)
- PR comments: [pr-comments.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/pr-comments.json), [view](https://k8s.devstats.cncf.io/d/23/pr-comments?orgId=1)
- PRs approval repository groups: [prs-approval-repository-groups.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/prs-approval-repository-groups.json), [view](https://k8s.devstats.cncf.io/d/26/prs-approval-repository-groups?orgId=1)
- PRs authors repository groups: [prs-authors-repository-groups.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/prs-authors-repository-groups.json), [view](https://k8s.devstats.cncf.io/d/30/prs-authors-repository-groups?orgId=1)
- PRs labels repository groups: [prs-labels-repository-groups.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/prs-labels-repository-groups.json), [view](https://k8s.devstats.cncf.io/d/47/prs-labels-repository-groups?orgId=1)
- SIG mentions: [sig-mentions.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig-mentions.json), [view](https://k8s.devstats.cncf.io/d/41/sig-mentions?orgId=1)
- Stars and Forks by Repository: [stars-and-forks-by-repository.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/stars-and-forks-by-repository.json), [view](https://k8s.devstats.cncf.io/d/7/stars-and-forks-by-repository?orgId=1)
- Time metrics by repository groups: [time-metrics-by-repository-groups.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/time-metrics-by-repository-groups.json), [view](https://k8s.devstats.cncf.io/d/44/time-metrics-by-repository-groups?orgId=1)

Metric SQL's are defined in [metrics.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml), search for dashboard name to find its SQL metric file.

All of them works live on [k8s.devstats.cncf.io](https://k8s.devstats.cncf.io) with auto `devstats` tool running.

See [adding new metrics](https://github.com/cncf/devstats/blob/master/METRICS.md) for details.

Similar set of metrics is defined for Prometheus, OpenTracing, ..., Rook (All CNCF Projects):

- SQL metrics in `metrics/prometheus/` directory, tags `metrics/prometheus/*tags*.sql` files. Prometheus dashboards: `grafana/dashboards/prometheus/` directory.
- SQL metrics in `metrics/opentracing/` directory, tags `metrics/opentracing/*tags*.sql` files. OpenTracing dashboards: `grafana/dashboards/opentracing/` directory.
- And so on...
- You can autogenerate list of dashboards using [vim script](https://github.com/cncf/devstats/blob/master/util_sh/auto_gen_dashboards_info.vim).

# Prometheus dashboards

All non-k8s projects currently have the same set of dashbords, you only need to replace prometheus with other project's name.

- Activity repository groups: [activity-repository-groups.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/activity-repository-groups.json), [view](https://prometheus.devstats.cncf.io/d/1/activity-repository-groups?orgId=1)
- Commits repository groups: [commits-repository-groups.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/commits-repository-groups.json), [view](https://prometheus.devstats.cncf.io/d/2/commits-repository-groups?orgId=1)
- Community stats: [community-stats.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/community-stats.json), [view](https://prometheus.devstats.cncf.io/d/3/community-stats?orgId=1)
- Companies stats: [companies-stats.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/companies-stats.json), [view](https://prometheus.devstats.cncf.io/d/4/companies-stats?orgId=1)
- Companies summary: [companies-summary.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/companies-summary.json), [view](https://prometheus.devstats.cncf.io/d/5/companies-summary?orgId=1)
- Contributing companies: [contributing-companies.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/contributing-companies.json), [view](https://prometheus.devstats.cncf.io/d/7/contributing-companies?orgId=1)
- Countries stats: [countries-stats.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/countries-stats.json), [view](https://prometheus.devstats.cncf.io/d/50/countries-stats?orgId=1)
- Dashboards: [dashboards.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/dashboards.json), [view](https://prometheus.devstats.cncf.io/d/8/dashboards?orgId=1)
- Developers summary: [developers-summary.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/developers-summary.json), [view](https://prometheus.devstats.cncf.io/d/9/developers-summary?orgId=1)
- First non-author activity: [first-non-author-activity.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/first-non-author-activity.json), [view](https://prometheus.devstats.cncf.io/d/10/first-non-author-activity?orgId=1)
- Gender stats: [gender-stats.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/gender-stats.json), [view](https://prometheus.devstats.cncf.io/d/49/gender-stats?orgId=1)
- Github events: [github-events.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/github-events.json), [view](https://prometheus.devstats.cncf.io/d/47/github-events?orgId=1)
- Issues age: [issues-age.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/issues-age.json), [view](https://prometheus.devstats.cncf.io/d/11/issues-age?orgId=1)
- Issues repository group: [issues-repository-group.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/issues-repository-group.json), [view](https://prometheus.devstats.cncf.io/d/12/issues-repository-group?orgId=1)
- New PRs: [new-prs.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/new-prs.json), [view](https://prometheus.devstats.cncf.io/d/15/new-prs?orgId=1)
- New and episodic contributors: [new-and-episodic-contributors.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/new-and-episodic-contributors.json), [view](https://prometheus.devstats.cncf.io/d/13/new-and-episodic-contributors?orgId=1)
- New and episodic issues: [new-and-episodic-issues.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/new-and-episodic-issues.json), [view](https://prometheus.devstats.cncf.io/d/14/new-and-episodic-issues?orgId=1)
- Opened to merged: [opened-to-merged.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/opened-to-merged.json), [view](https://prometheus.devstats.cncf.io/d/16/opened-to-merged?orgId=1)
- PR comments: [pr-comments.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/pr-comments.json), [view](https://prometheus.devstats.cncf.io/d/17/pr-comments?orgId=1)
- PRs age: [prs-age.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/prs-age.json), [view](https://prometheus.devstats.cncf.io/d/19/prs-age?orgId=1)
- PRs approval: [prs-approval.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/prs-approval.json), [view](https://prometheus.devstats.cncf.io/d/20/prs-approval?orgId=1)
- PRs authors: [prs-authors.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/prs-authors.json), [view](https://prometheus.devstats.cncf.io/d/23/prs-authors?orgId=1)
- PRs authors companies histogram: [prs-authors-companies-histogram.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/prs-authors-companies-histogram.json), [view](https://prometheus.devstats.cncf.io/d/21/prs-authors-companies-histogram?orgId=1)
- PRs authors histogram: [prs-authors-histogram.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/prs-authors-histogram.json), [view](https://prometheus.devstats.cncf.io/d/22/prs-authors-histogram?orgId=1)
- PRs merged repository groups: [prs-merged-repository-groups.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/prs-merged-repository-groups.json), [view](https://prometheus.devstats.cncf.io/d/24/prs-merged-repository-groups?orgId=1)
- Project statistics: [project-statistics.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/project-statistics.json), [view](https://prometheus.devstats.cncf.io/d/18/project-statistics?orgId=1)
- Repository commenters: [repository-commenters.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/repository-commenters.json), [view](https://prometheus.devstats.cncf.io/d/25/repository-commenters?orgId=1)
- Repository comments: [repository-comments.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/repository-comments.json), [view](https://prometheus.devstats.cncf.io/d/26/repository-comments?orgId=1)
- Time metrics: [time-metrics.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/time-metrics.json), [view](https://prometheus.devstats.cncf.io/d/27/time-metrics?orgId=1)
- Timezone stats: [timezones-stats.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/timeones-stats.json), [view](https://prometheus.devstats.cncf.io/d/51/timezones-stats?orgId=1)
- Top commenters: [top-commenters.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/top-commenters.json), [view](https://prometheus.devstats.cncf.io/d/28/top-commenters?orgId=1)
- User reviews: [user-reviews.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/user-reviews.json), [view](https://prometheus.devstats.cncf.io/d/46/user-reviews?orgId=1)
- Users stats: [users-stats.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/users-stats.json), [view](https://prometheus.devstats.cncf.io/d/48/users-stats?orgId=1)

There is also an 'All' [Project](https://all.devstats.cncf.io) on the test server that contains all CNCF projects data combined. Each CNCF projects is a repository group there.

# Adding new project

To add new project follow [adding new project](https://github.com/cncf/devstats/blob/master/ADDING_NEW_PROJECT.md) instructions.
