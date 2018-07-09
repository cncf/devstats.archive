# GitHub Archives

Project uses use GitHub archives and local copy of all git repositories. The possible alternatives are:

1) BigQuery:
- You can query any data you want, but the structure is quite flat and entire GitHub event payloads are stored as a single column containing JSON text.
- This limits usage due to the need of parsing that JSON in DB queries.
- BigQuery is commercial, paid and is quite expensive.
- It is not a standard SQL.

2) GitHub API:
- You can get the current state of the objects, but you cannot get repo, PR, issue state in the past (for example summary fields, etc).
- It is limited by GitHub API usage per hour, which makes local development harder.
- API limits are very aggressive for unauthorized access, and even with authorized access, you're limited to 5000 API calls/hour. With this limit, it would take more than 2 months to get all Kubernetes GitHub events (estimate).
- It is much slower than processing GitHub archives or BigQuery.
- You must query it via API and it is returning a single result.
- You can use GitHub hook callbacks, but they only fire for current events.

3) GitHub archives
- All GitHub events are packed into multi-json gzipped files each hour and made available from [Github Archive](https://www.githubarchive.org/). To use this data, you need to extract all hours (since the Kubernetes project started) and filter out all data except for events from the 4 kubernetes organizations ([kubernetes](https://github.com/kubernetes), [kubernetes-incubator](https://github.com/kubernetes-incubator), [kubernetes-client](https://github.com/kubernetes-client), [kubernetes-csi](https://github.com/kubernetes-csi)).
- This is a lot of data to process, but you have all possible GitHub events in the past, processing more than 3 years of this data takes about 2-2,5 hours, but this must only be done once and then the processed results are available for other's use.
- You have a lot of data in a single file, that can be processed/filtered in memory.
- You are getting all possible events, and all of them include the current state of PRs, issues, repos at given point in time.
- Processing of GitHub archives is free, so local development is easy.
- GitHub archives format changed in 2015-01-01, so it is using older format (pre-2015) before that date, and newer after. For details please see [USAGE](https://github.com/cncf/devstats/blob/master/USAGE.md), specially `GHA2DB_OLDFMT` environment variable.
- I have 1.2M events in my Psql database, and each event contains quite complex structure, I would estimate about 3-6 GitHub API calls are needed to get that data. It means about 7M API calls.
- 7.2M / 5K (API limit per hour) gives 1440 hours which is 2 months. And we're on GitHub API limit all the time. Processing ALL GitHub events takes about 2 hours without ANY limit.
- You can optionally save downloaded JSONs to avoid network traffic in next calls (also usable for local development mode).
- There is an already implemented version in Go, please see usage here [USAGE](https://github.com/cncf/devstats/blob/master/USAGE.md)
- Dashboards can be displayed here [link](https://k8s.devstats.cncf.io/?orgId=1)

4) Project also uses `git` to store local copy of all projects repositories to allow file related analysis (like list of files changed in a given commit, file sizes etc.).
- All projects repositories are cloned into local directory
- All projects repositories are updated every hour using `git` (part of standard cron workflow).
- For all commits retrieved from GitHub archives we are storing list of modified (modified, added, deleted) files and their size (at the commit time).
- This allows file name analsysis, assigning given files from repositories to repository groups (file level granularity) and file size analysis (for example file size growth in time).

# Architecture

We're getting all possible GitHub data for all objects, and all objects historical state as well (not discarding any data). We are also keeping copy of all git repositories used in all projects and update it every hour:

1) `structure` (manages database structure, summaries, views)
- [structure](https://github.com/cncf/devstats/blob/master/cmd/structure/structure.go)
- It is used to create database structure, indexes and to update database summary tables, views etc.
- Postgres advantages over MySQL include:
- Postgres supports hash joins that allows multi-million table joins in less than 1s, while MySQL requires more than 3 minutes. MySQL had to use data duplication in multiple tables to create fast metrics.
- Postgres has built-in fast REGEXP extract & match, while MySQL only has slow REGEXP match and no REGEXP extract, requiring external libraries like `lib_mysql_pcre` to be installed.
- Postgres supports materialized views - so complex metrics can be stored by such views, and we only need to refresh them when syncing data. MySQL requires creating an additional table and managing it.
- MySQL has utf8 related issues, I've found finally workaround that requires to use `utf8mb4` and do some additional `mysqld` configuration.

2) `gha2db` (imports GitHub archives to database and eventually JSON files)
- [devstats](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go)
- Reads from GitHub archive and writes to Postgres
- It saves ALL data from GitHub archives, so we have all GitHub structures fully populated. See [Database structure](https://github.com/cncf/devstats/blob/master/USAGE.md).
- We have all historical data from all possible GitHub events and summary values for repositories at given points of time.
- The idea is to divide all data into two categories: `const` and `variable`. Const data is a data that is not changing in time, variable data is a data that changes in time, so `event_id` is added as a part of this data primary key.
- Table structure, `const` and `variable` description can be found in [USAGE](https://github.com/cncf/devstats/blob/master/USAGE.md)
- The program can be parallelized very easy (events are distinct in different hours, so each hour can be processed by other CPU), uses 48 CPUs on our test machine.

3) `calc_metric` (computes metrics given as SQL files to be run on Postgres and saves time series output to time series)
- [calc_metric](https://github.com/cncf/devstats/blob/master/cmd/calc_metric/calc_metric.go)
- This separates metrics complex logic in SQL files, `calc_metric` executes parameterized SQL files and write final data as a time-series (also on Postgres).
- Parameters are `'{{from}}'`, `'{{to}}'` to allow computing the given metric for any date period.
- For histogram metrics there is a single parameter `'{{period}}'` instead. To run `calc_metric` in histogram mode add "h" as last parameter after all other params. `gha2db_sync` already handles this.
- This means that time series tables will only hold multiple time-series (very simple data).
- Grafana will read from Postgres time series.
- Adding new metric will mean add Postgres SQL that will compute this metric.

4) `gha2db_sync` (synchronizes data sources and Postgres databases)
- [gha2db_sync](https://github.com/cncf/devstats/blob/master/cmd/gha2db_sync/gha2db_sync.go)
- This program figures out what is the most recent data in Postgres database then queries GitHub archive from this date to current date.
- It will add data to Postgres database (since the last run)
- It will update summary tables and/or (materialized) views on Postgres DB.
- It will update new commits files list using `get_repos` program.
- Then it will call `calc_metric` for all defined SQL metrics and update time series data database as well.
- You need to set `GHA2DB_PROJECT=project_name` currently it can be either kubernetes, prometheus or opentracing. Projects are defined in `projects.yaml` file.
- It reads a list of metrics from YAML file: `metrics/{{project}}/metrics.yaml`, some metrics require to fill gaps in their data. Those metrics are defined in another YAML file `metrics/{{project}}/gaps.yaml`. Please try to use Grafana's "nulls as zero" instead of using gaps filling.
- This tool also supports initial computing of all time series data (instead of default update since the last run).
- It can be called by cron job on 1:10, 2:10, ... and so on - GitHub archive publishes new file every hour, so we're off by at most 1 hour.
- It can also be called automatically by `devstats` tool

5) `devstats` (calls `gha2db_sync` for all defined projects)
- [devstats](https://github.com/cncf/devstats/blob/master/cmd/devstats/devstats.go)
- This program will read `projects.yaml` call `get_repos` to update all projects git repos, then call `gha2db_sync` for all defined projects that are not disabled by `disabled: true`.
- It uses own database just to store logs from running project syncers, this is a Postgres database "devstats".
- It creates PID file `/tmp/devstats.pid` while it is running, so it is safe when instances overlap.
- It is called by cron job on 1:10, 2:10, ... and so on - GitHub archive publishes new file every hour, so we're off by at most 1 hour.

6) `get_repos`: it can update list of all projects repositories (clone and/or pull as needed), update each commits files list, display all repos and orgs data bneeded by `cncf/gitdm`.
- [get_repos](https://github.com/cncf/devstats/blob/master/cmd/get_repos/get_repos.go)
- `get_repos` is used to clone or pull all repos used in all `devstats` project in a location from `GHA2DB_REPOS_DIR` environment variable, or by default in "~/devstats_repos/".
- Those repos are used later to search for commit SHA's using `git log` to determine files modifed by particular commits and other objects.
- It can also be used to return list of all distinct repos and their locations - this can be used by `cncf/gitdm` to create concatenated `git.log` from all repositories for affiliations analysis.
- This tool is also used to create/update mapping between commits and list of files that given commit refers to, it also keep file sizes info at the commit time.

7) `ghapi2db`: it uses GitHub API to get labels and milestones information for all open issues and PRs from last 2 hours.
- [ghapi2db](https://github.com/cncf/devstats/blob/master/cmd/ghapi2db/ghapi2db.go).
- Issues/PRs contain labels/milestones information from the last GitHub event on those issues/PR. This is a state from last issue comment.
- Sometimes labels and/or milestone information is changed after the last commit. New issue labels/milestone will only be visible after the next issue comment.
- This tool queries all open issues/PRs from last 2 hours to check their label set and milestone. If it detects difference it creates artificial events with the new state.
- This is used by 'Open issues/PRs by milestone' dashboard to make sure that we have correct informations.
- GitHub API points are limited to 5000/hour, use `GHA2DB_GITHUB_OAUTH` env variable to set GitHub OAUth token path. Default is `/etc/github/oauth`. You can set to "-" to force public acces, but you will be limited to 60 API calls/hour.

8) Additional stuff, most important being `runq`  and `import_affs` tools.
- [runq](https://github.com/cncf/devstats/blob/master/cmd/runq/runq.go)
- `runq` gets SQL file name and parameter values and allows to run metric manually from the command line (this is for local development)
- [import_affs](https://github.com/cncf/devstats/blob/master/cmd/import_affs/import_affs.go)
- `import_affs` takes one parameter - JSON file name (this is a file from [cncf/gitdm](https://github.com/cncf/gitdm): [github_users.json](https://raw.githubusercontent.com/cncf/gitdm/master/github_users.json)
- This tools imports GitHub usernames (in addition to logins from GHA) and creates developers - companies affiliations (that can be used by [Companies stats](https://k8s.devstats.cncf.io/dashboard/db/companies-stats?orgId=1) metric)
- [annotations](https://github.com/cncf/devstats/blob/master/cmd/annotations/annotations.go)
- `annotations` is used to add annotations on charts. It uses GitHub API to fetch tags from project main repository defined in `projects.yaml`, it only includes tags matching annotation regexp also defined in `projects.yaml`.
- [tags](https://github.com/cncf/devstats/blob/master/cmd/tags/tags.go)
- `tags` is used to add tags. Those tags are used to populate Grafana template drop-down values and names. This is used to auto-populate Repository groups drop down, so when somebody adds new repository group - it will automatically appear in the drop-down.
- `tags` uses [tags.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/tags.yaml) file to configure tags generation.
- [columns](https://github.com/cncf/devstats/blob/master/cmd/columns/columns.go)
- `columns` is used to specify which columns are mandatory on which time series tables (because missing column is an error in Postgres). You can define table9s) by regexp and then specify which columns are mandatory by specifying tags table and column. 
- `columns` uses [columns.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/columns.yaml) file to configure mandatory columns.
- You can use all defined environments variables, but add `_SRC` suffic for source database and `_DST` suffix for destination database.
- [webhook](https://github.com/cncf/devstats/blob/master/cmd/webhook/webhook.go)
- `webhook` is used to react to Travis CI webhooks and trigger deploy if status, branch and type match defined values, more details [here](https://github.com/cncf/devstats/blob/master/CONTINUOUS_DEPLOYMENT.md).
- Add `[no deploy]` to the commit message, to skip deploying.
- Add `[ci skip]` to skip testing (will not spawn Travis CI build).
- Add `[deploy]` to do a full deploy using `./devel/deploy_all.sh` script, this needs more environment variables to be set, see [here](https://github.com/cncf/devstats/blob/master/CONTINUOUS_DEPLOYMENT.md).
- There are few shell scripts for example: running sync every N seconds, setup time series data etc.
- [merge_dbs](https://github.com/cncf/devstats/blob/master/cmd/merge_dbs/merge_dbs.go)
- `merge_dbs` is used to generate Postgres database that contains data from other multiple databases.
- You can use `merge_dbs` to add new projects to a existing database, but please consider running './devel/remove_db_dups.sh' then or use: './all/add_project.sh' script.
- [replacer](https://github.com/cncf/devstats/blob/master/cmd/replacer/replacer.go)
- `replacer` is used to mass replace data in text files. It has regexp modes, string modes, terminate on no match etc.
- [vars](https://github.com/cncf/devstats/blob/master/cmd/vars/vars.go)
- `vars` is used to add special variables (tags) to the database, see [here](https://github.com/cncf/devstats/blob/master/docs/vars.md) for more info.
- [sqlitedb](https://github.com/cncf/devstats/blob/master/cmd/sqlitedb/sqlitedb.go)
- `sqlitedb` is used to manipulate Grafana's SQLite database, see [here](https://github.com/cncf/devstats/blob/master/SQLITE.md) for more info.

# Database structure details

The main idea is that we divide tables into 2 groups:
- const: meaning that data in this table is not changing in time (is saved once)
- variable: meaning that data in those tables can change between GH events, and GH `event_id` is a part of this tables primary key.
- there are also "compute" tables that are auto-updated by `gha2db_sync`/`structure` tools and affiliations table that is filled by `import_affs` tool.

Please see [USAGE](https://github.com/cncf/devstats/blob/master/USAGE.md) for detailed list of database tables.

# Benchmarks

Ruby version was dropped, but you can see benchmarks of Ruby using MySQL, Ruby using Postgres and current Go using Postgres here:

[Historical benchmarks](https://github.com/cncf/devstats/blob/master/BENCHMARK.md)

In summary: Go version can import all GitHub archives data (not discarding anything) for all Kubernetes orgs/repos, from the beginning on GitHub 2014-06-01 in about 2-2,5 hours! Cloning all projects repositories takes about 15 minutes when done for a first time and takes about 12 GB disk space.
