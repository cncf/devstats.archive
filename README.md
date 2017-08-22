# GitHub Archives Visualisation

This is a toolset to visualize GitHub archives using Grafana dashboards.

# Goal

We want to create various metrics visualization toolset for Kubernetes community.

It already has some metrics visualization: `kubernetes/test-infra` `velodrome`.

This project aims to add new metrics for existing Grafana dashboards.

We want to support all kind of metrics, including historical ones.

Please see [requested metrics](https://docs.google.com/document/d/1ShHr3cNCTXhtm0tKJrqI1wG_QJ2ahZBsQ7UDllfc2Dc/edit) to see what kind of metrics are needed.

Many of them cannot be computed currently and current MySQL database has not enough data.

Current Velodrome implementation uses GitHub API to get its data. This has some limitations:
- It is not able to get repo, PR state at any given point of history
- It is limited by GitHub API points usage.

# GitHub Archives

My approach is to use GitHub archives instead.
Possible alternatives are:

1) BigQuery:
- You can query any data you want, but the structure is quite flat and entire GitHub event payloads are stored as a single column containing JSON text.
- This limits usage due to the need of parsing that JSON in DB queries.
- BigQuery is commercial, paid and is quite expensive.
- It is not a standard SQL.

2) GitHub API:
- You can get the current state of the objects, but you cannot get repo, PR, issue state in the past (for example summary fields etc).
- It is limited by GitHub API usage per hour, which makes local development harder.
- API limits are very aggressive for unauthorized access, and even with authorized access, you're limited to 5000 API calls/hour.
- It is much slower than processing GitHub archives or BigQuery
- You must query it via API and it is returning a single result.
- You can use GitHub hook callbacks, but they only fire for current events.

3) GitHub archives
- All GitHub events are packed into multi-json gzipped files for each hour, you need to extract all hours (since Kubernetes project started) and filter 3 kubernetes orgs events.
- This is a lot of data to process, but you have all possible GitHub events in the past, processing 2 years of this data takes 12 hours, but this is done already and must be done only once.
- You have a lot of data in a single file, that can be processed/filtered in memory.
- You are getting all possible events, and all of them include the current state of PRs, issues, repos at given point in time.
- Processing of GitHub archives is free, so local development is easy.
- I have 1.2M events in my Psql database, and each event contains quite complex structure, I would estimate about 3-6 GitHub API calls are needed to get that data. It means about 7M API calls.
- 7.2M / 5K (API limit per hour) gives 1440 hours which is 2 months. And we're on GitHub API limit all the time. Processing ALL GitHub events takes about 12 hours without ANY limit.
- You can optionally save downloaded JSONs to avoid network traffic in next calls (also usable for local development mode).
- There is already implemented proof of concept (POC), please see [Ruby version README](https://github.com/cncf/gha2db/blob/master/README.ruby.md)
- It implements 5 example metrics: Reviewers, SIG mentions, PRs merged per repo, PRs merged in all repos, Time to merge, please see [Dashboards](https://cncftest.io/?orgId=1)

# Proposed architecture

Velodrome consists of 3 parts:
- `Fetcher` - it is used to query GitHub API and store results in MySQL database (but only a small part of data available is stored)
- `Transform` - it is used to compute some metrics on MySQL database and save them as InfluxDB series
- `Grafana` - displays data from InfluxDB time series.

My architecture is quite similar (but I'm getting all possible GitHub data for all objects, and all objects historical state as well).
It consists of:

1) `structure` (manages database structure, summaries, views)
- This is implemented as [structure.rb](https://github.com/cncf/gha2db/blob/master/structure.rb) in POC.
- It is used to create database structure, indexes and to update database summary tables, views etc.
- POC supports both MySQL and Postgres. Tests have shown that Postgres is a way better than MySQL for this.
- Postgres supports hash joins that allows multi-million table joins in less than 1s, while MySQL requires more than 3 minutes. MySQL had to use data duplication in multiple tables to create fast metrics.
- Postgres has built-in fast REGEXP extract & match, while MySQL only has slow REGEXP match and no REGEXP extract, requiring external libraries like `lib_mysql_pcre` to be installed.
- Postgres supports materialized views - so complex metrics can be stored by such views, and we only need to refresh them when syncing data. MySQL requires creating an additional table and managing it.
- MySQL has utf8 related issues, I've found finally workaround that requires to use `utf8mb4` and do some additional `mysqld` configuration.

2) `gha2db` (imports GitHub archives to database and eventually JSON files)
- This is implemented as [gha2db.rb](https://github.com/cncf/gha2db/blob/master/gha2db.rb) in POC.
- This is a `fetcher` equivalent, differences are that it reads from GitHub archive instead of GitHub API and writes to Postgres instead of MySQL
- It saves ALL data from GitHub archives, so we have all GitHub structures fully populated. See [Database structure](https://github.com/cncf/gha2db/blob/master/README.ruby.md).
- We have all historical data from all possible GitHub events and summary values for repositories at given points of time.
- The idea is to divide all data into two categories: `const` and `variable`. Const data is a data that is not changing in time, variable data is a data that changes in time, so `event_id` is added as a part of this data primary key.
- Table structure, `const` and `variable` description can be found in [Ruby version readme](https://github.com/cncf/gha2db/blob/master/README.ruby.md)
- The program can be parallelized very easy (events are distinct in different hours, so each hour can be processed by other CPU), POC uses 48 CPUs on cncftest.io.

3) `db2influx` (computes metrics given as SQL files to be run on Postgres and saves time series output to InfluxDB)
- This is implemented as [db2influx.rb](https://github.com/cncf/gha2db/blob/master/db2influx.rb) in POC.
- This separates metrics complex logic in SQL files, `db2influx` executes parameterized SQL files and write final time-series to InfluxDB.
- Parameters are `'{{from}}'`, `'{{to}}'` to allow computing the given metric for any date period.
- This means that InfluxDB will only hold multiple time-series (very simple data). InfluxDB is extremely good at manipulating such kind of data - this is what it was created for.
- Grafana will read from InfluxDB by default and will use its power to generate all possible aggregates, minimums, maximums, averages, medians, percentiles, charts etc.
- Adding new metric will mean add Postgres SQL that will compute this metric.
- Grafana can read from MySQL database directly but: it is slower that time-series Influx (which is designed for that), and also we are preferring Postgres as described above. So we're skipping direct MySQL usage path.

4) `sync` (synchronizes GitHub archive data and Postgres, InfluxDB databases)
- This is implemented as [sync.rb](https://github.com/cncf/gha2db/blob/master/sync.rb) in POC.
- This program figures out what is the most recent data in Postgres database then queries GitHub archive from this date to current date.
- It will add data to Postgres database (since the last run)
- It will update summary tables and/or (materialized) views on Postgres DB.
- Then it will call `db2influx` for all defined SQL metrics.
- When adding new metrics, it needs to be called here.
- This tool also supports initial computing of All InfluxDB data (instead of default update since last run).
- It will be called from cron job at least every 45 minutes - GitHub archive publishes new file every hour, so we're off by at most 1 hour.

5) Additional stuff
- This is implemented as [runq.rb](https://github.com/cncf/gha2db/blob/master/runq.rb) and various `*.sh` shell scripts in POC.
- `runq` gets SQL file name and parameter values and allows to run metric manually from the command line (this is for local development)
- There are few shell scripts for example: running sync every N seconds, setup InfluxDB etc.

# Current Velodrome

My toolset can either replace velodrome or just add value to `velodrome`.

They both can use shared InfluxDB (I will name series in such a way to avoid conflicts with existing ones).

Then we can just add new dashboards that use my `gha2db`/`db2influx` workflow in the existing Grafana, and add a cron job that will keep them up to date.

# Adding new metrics

To add new metrics we need to:
1) Define parameterized SQL (with `{{from}}` and `{{to}}` params) that returns this metric data.
2) Add `db2influx` call for this metric in `sync` tool. 
3) Add Grafana dashboard or row that displays this metric
4) Export new Grafana dashboard to JSON
5) Create PR for the new metric.

# Local development
Local development is much easier:
1) Install psql, influx, grafana - all with default options.
2) Fetch populated psql database [Postgres database dump](https://cncftest.io/web/k8s_psql.sql.xz)
3) Just run Go tools manually: `structure`, `gha2db`, `db2influx`, `sync`, `runq`.

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
- `gha_events_commits`: variable, event's commits
- `gha_events_pages`: variable, event's pages
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

Here are already working dashboards (written in Ruby) using this repo.

1) [Reviewers](https://cncftest.io/dashboard/db/reviewers?orgId=1).
2) [SIG mentions](https://cncftest.io/dashboard/db/sig-mentions?orgId=1).
3) [PRs merged per repo](https://cncftest.io/dashboard/db/prs-merged?orgId=1).
4) [PRs merged in all repos](https://cncftest.io/dashboard/db/all-prs-merged?orgId=1).
5) [Time to merge](https://cncftest.io/dashboard/db/time-to-merge?orgId=1).

All of them works live on [cncftest.io](https://cncftest.io) with auto sync tool running.

