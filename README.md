# GitHub Archives Visualization

Author: Łukasz Gryglicki <lukaszgryglick@o2.pl>

This is a toolset to visualize GitHub [archives](https://www.githubarchive.org/) using Grafana dashboards.

# Goal

We want to create a toolset for visualizing various metrics for the Kubernetes community.
Everything is open source so that it can be used by other CNCF and non-CNCF open source projects.
The work builds on the [Velodrome](https://github.com/kubernetes/test-infra/tree/master/velodrome) tool that was built by [apelisse](https://github.com/apelisse) and others.

This project aims to add new metrics for the existing Grafana dashboards.
We want to support all kind of metrics, including historical ones.
Please see [requested metrics](https://docs.google.com/document/d/1ShHr3cNCTXhtm0tKJrqI1wG_QJ2ahZBsQ7UDllfc2Dc/edit) to see what kind of metrics are needed.
Many of them cannot be computed based on the data sources currently used.

The current Velodrome implementation uses the GitHub API to get its data. This has some limitations:
- It is not able to get repo and PR state at any given point of history
- It is limited by GitHub API token rate limits.

# GitHub Archives

Our approach is to use GitHub archives instead. The possible alternatives are:

1) BigQuery:
- You can query any data you want, but the structure is quite flat and entire GitHub event payloads are stored as a single column containing JSON text.
- This limits usage due to the need of parsing that JSON in DB queries.
- BigQuery is commercial, paid and is quite expensive.
- It is not a standard SQL.

2) GitHub API:
- You can get the current state of the objects, but you cannot get repo, PR, issue state in the past (for example summary fields, etc).
- It is limited by GitHub API usage per hour, which makes local development harder.
- API limits are very aggressive for unauthorized access, and even with authorized access, you're limited to 5000 API calls/hour.
- It is much slower than processing GitHub archives or BigQuery
- You must query it via API and it is returning a single result.
- You can use GitHub hook callbacks, but they only fire for current events.

3) GitHub archives
- All GitHub events are packed into multi-json gzipped files each hour and made available from [Github Archive](https://www.githubarchive.org/). To use this data, you need to extract all hours (since the Kubernetes project started) and filter out all data except for events from the 3 kubernetes organizations ([kubernetes](https://github.com/kubernetes), [kubernetes-incubator](https://github.com/kubernetes-incubator), and [kubernetes-client](https://github.com/kubernetes-client).
- This is a lot of data to process, but you have all possible GitHub events in the past, processing 2 years of this data takes 2 hours, but this must only be done once and then the processed results are available for other's use.
- You have a lot of data in a single file, that can be processed/filtered in memory.
- You are getting all possible events, and all of them include the current state of PRs, issues, repos at given point in time.
- Processing of GitHub archives is free, so local development is easy.
- I have 1.2M events in my Psql database, and each event contains quite complex structure, I would estimate about 3-6 GitHub API calls are needed to get that data. It means about 7M API calls.
- 7.2M / 5K (API limit per hour) gives 1440 hours which is 2 months. And we're on GitHub API limit all the time. Processing ALL GitHub events takes about 2 hours without ANY limit.
- You can optionally save downloaded JSONs to avoid network traffic in next calls (also usable for local development mode).
- There is already implemented proof of concept (POC), please see usage here [USAGE](https://github.com/cncf/gha2db/blob/master/USAGE.md)
- POC is implemented in Go.
- It implements 5 example metrics: Reviewers, SIG mentions, PRs merged per repo, PRs merged in all repos, Time to merge, please see [Dashboards](https://cncftest.io/?orgId=1)

# Proposed architecture

Velodrome consists of 3 parts:
- `Fetcher` - it is used to query GitHub API and store results in MySQL database (but only a small part of data available is stored)
- `Transform` - it is used to compute some metrics on MySQL database and save them as InfluxDB series
- `Grafana` - displays data from InfluxDB time series.

Our architecture is quite similar, but we're getting all possible GitHub data for all objects, and all objects historical state as well. It consists of:

1) `structure` (manages database structure, summaries, views)
- [structure](https://github.com/cncf/gha2db/blob/master/cmd/structure/structure.go)
- It is used to create database structure, indexes and to update database summary tables, views etc.
- Ruby version supported both MySQL and Postgres. Tests have shown that Postgres is a way better than MySQL for this.
- Go version only supports Postgres. Ruby version is removed and no longer maintained.
- Postgres supports hash joins that allows multi-million table joins in less than 1s, while MySQL requires more than 3 minutes. MySQL had to use data duplication in multiple tables to create fast metrics.
- Postgres has built-in fast REGEXP extract & match, while MySQL only has slow REGEXP match and no REGEXP extract, requiring external libraries like `lib_mysql_pcre` to be installed.
- Postgres supports materialized views - so complex metrics can be stored by such views, and we only need to refresh them when syncing data. MySQL requires creating an additional table and managing it.
- MySQL has utf8 related issues, I've found finally workaround that requires to use `utf8mb4` and do some additional `mysqld` configuration.

2) `gha2db` (imports GitHub archives to database and eventually JSON files)
- [gha2db](https://github.com/cncf/gha2db/blob/master/cmd/gha2db/gha2db.go)
- This is a `fetcher` equivalent, differences are that it reads from GitHub archive instead of GitHub API and writes to Postgres instead of MySQL
- It saves ALL data from GitHub archives, so we have all GitHub structures fully populated. See [Database structure](https://github.com/cncf/gha2db/blob/master/USAGE.md).
- We have all historical data from all possible GitHub events and summary values for repositories at given points of time.
- The idea is to divide all data into two categories: `const` and `variable`. Const data is a data that is not changing in time, variable data is a data that changes in time, so `event_id` is added as a part of this data primary key.
- Table structure, `const` and `variable` description can be found in [USAGE](https://github.com/cncf/gha2db/blob/master/USAGE.md)
- The program can be parallelized very easy (events are distinct in different hours, so each hour can be processed by other CPU), POC uses 48 CPUs on cncftest.io.

3) `db2influx` (computes metrics given as SQL files to be run on Postgres and saves time series output to InfluxDB)
- [db2influx](https://github.com/cncf/gha2db/blob/master/cmd/db2influx/db2influx.go)
- This separates metrics complex logic in SQL files, `db2influx` executes parameterized SQL files and write final time-series to InfluxDB.
- Parameters are `'{{from}}'`, `'{{to}}'` to allow computing the given metric for any date period.
- This means that InfluxDB will only hold multiple time-series (very simple data). InfluxDB is extremely good at manipulating such kind of data - this is what it was created for.
- Grafana will read from InfluxDB by default and will use its power to generate all possible aggregates, minimums, maximums, averages, medians, percentiles, charts etc.
- Adding new metric will mean add Postgres SQL that will compute this metric.

4) `sync` (synchronizes GitHub archive data and Postgres, InfluxDB databases)
- [sync](https://github.com/cncf/gha2db/blob/master/cmd/sync/sync.go)
- This program figures out what is the most recent data in Postgres database then queries GitHub archive from this date to current date.
- It will add data to Postgres database (since the last run)
- It will update summary tables and/or (materialized) views on Postgres DB.
- Then it will call `db2influx` for all defined SQL metrics.
- When adding new metrics, it needs to be called here.
- This tool also supports initial computing of All InfluxDB data (instead of default update since last run).
- It will be called from cron job at least every 45 minutes - GitHub archive publishes new file every hour, so we're off by at most 1 hour.

5) Additional stuff, most important being `runq` tool.
- [runq](https://github.com/cncf/gha2db/blob/master/cmd/runq/runq.go)
- `runq` gets SQL file name and parameter values and allows to run metric manually from the command line (this is for local development)
- There are few shell scripts for example: running sync every N seconds, setup InfluxDB etc.

Detailed usage is here [USAGE](https://github.com/cncf/gha2db/blob/master/USAGE.md)

# Current Velodrome

This toolset can either replace velodrome or just add value to `velodrome`.

They both can use shared InfluxDB (We are naming series in such a way to avoid conflicts with existing ones).

Then we can just add new dashboards that use my `gha2db`/`db2influx` workflow in the existing Grafana, and add a cron job that will keep them up to date.

# Adding new metrics

To add new metrics we need to:
1) Define parameterized SQL (with `{{from}}` and `{{to}}` params) that returns this metric data.
2) Add `db2influx` call for this metric in `sync` tool. 
3) Add test coverage in [metrics_test.go](https://github.com/cncf/gha2db/blob/master/metrics_test.go).
4) Add Grafana dashboard or row that displays this metric
5) Export new Grafana dashboard to JSON
6) Create PR for the new metric.

# Local development
Local development is much easier:
1) Install psql, influx, grafana - all with default options.
2) Fetch populated psql database [Postgres database dump](https://cncftest.io/web/k8s.sql.xz)
3) Just run Go tools manually: `structure`, `gha2db`, `db2influx`, `sync`, `runq`.
4) Run tests locally, plaese see [testing](https://github.com/cncf/gha2db/blob/master/TESTING.md)

# Database structure details

The main idea is that we divide tables into 2 groups:
- const: meaning that data in this table is not changing in time (is saved once)
- variable: meaning that data in those tables can change between GH events, and GH `event_id` is a part of this tables primary key.

List of tables:
- `gha_actors`: const, users table
- `gha_assets`: variable, assets
- `gha_branches`: variable, branches data
- `gha_comments`: variable (issue, PR, review)
- `gha_commits`: variable, commits
- `gha_events`: const, single GitHub archive event
- `gha_forkees`: variable, forkee, repo state
- `gha_issues`: variable, issues
- `gha_issues_assignees`: variable, issue assignees
- `gha_issues_labels`: variable, issue labels
- `gha_labels`: const, labels
- `gha_milestones`: variable, milestones
- `gha_orgs`: const, orgs
- `gha_pages`: variable, pages
- `gha_payloads`: const, event payloads
- `gha_pull_requests`: variable, pull requests
- `gha_pull_requests_assignees`: variable pull request assignees
- `gha_pull_requests_requested_reviewers`: variable, pull request requested reviewers
- `gha_releases`: variable, releases
- `gha_releases_assets`: variable, release assets
- `gha_repos`: const, repos

# POC dashboards

Here are already working dashboards using this repo.

Each dashboard is defined by its metrics SQL, saved Grafana JSON export and link to dashboard running on <https://cncftest.io>

1) Reviewers dashboard: [reviewers.sql](https://github.com/cncf/gha2db/blob/master/metrics/reviewers.sql), [reviewers.json](https://github.com/cncf/gha2db/blob/master/grafana/dashboards/reviewers.json), [view](https://cncftest.io/dashboard/db/reviewers?orgId=1).
2) SIG mentions dashboard: [sig_mentions.sql](https://github.com/cncf/gha2db/blob/master/metrics/sig_mentions.sql), [sig_mentions.json](https://github.com/cncf/gha2db/blob/master/grafana/dashboards/sig_mentions.json), [view](https://cncftest.io/dashboard/db/sig-mentions?orgId=1).
3) Number of PRs merged in all Kubernetes repos [all_prs_merged.sql](https://github.com/cncf/gha2db/blob/master/metrics/all_prs_merged.sql), [all_prs_merged.json](https://github.com/cncf/gha2db/blob/master/grafana/dashboards/all_prs_merged.json), [view](https://cncftest.io/dashboard/db/all-prs-merged?orgId=1).
4) Number of PRs merged per repository [prs_merged.sql](https://github.com/cncf/gha2db/blob/master/metrics/prs_merged.sql), [prs_merged.json](https://github.com/cncf/gha2db/blob/master/grafana/dashboards/prs_merged.json), [view](https://cncftest.io/dashboard/db/prs-merged?orgId=1).
5) Average time from PR open to merge [opened_to_merged.sql.json](https://github.com/cncf/gha2db/blob/master/metrics/opened_to_merged.sql), [time_to_merge.json](https://github.com/cncf/gha2db/blob/master/grafana/dashboards/time_to_merge.json), [view](https://cncftest.io/dashboard/db/time-to-merge?orgId=1).

All of them works live on [cncftest.io](https://cncftest.io) with auto sync tool running.

# Detailed USAGE instructions

- [USAGE](https://github.com/cncf/gha2db/blob/master/USAGE.md)

# Benchmarks

Ruby version was dropped, but You can see benchmarks of Ruby using MySQL, Ruby using Postgres and current Go using Postgres here:

[Benchmarks](https://github.com/cncf/gha2db/blob/master/BENCHMARK.md)

In summary: Go version can import all GitHub archives data (not discarding anything) for all Kubernetes orgs/repos, from the beginning on GitHub 2015-08-06 in about 2 hours!

