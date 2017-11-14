# GitHub Archives to Postgres, InfluxDB, Grafana

Author: Łukasz Gryglicki <lukaszgryglick@o2.pl>

# Implemented in two languages (history)

This toolset was first implemented in Ruby with Postgres database.

Then MySQL support was added.

MySQL proved to be slower and harder to use than Postgres.

Entire toolset was rewritten in Go.

Go version only support Postgres, it proved to be a lot faster than Ruby version.

Finally, Ruby version was dropped.

This tools filter GitHub archive for given date period and given organization, repository and save results in a Postgres database.
It can also save results into JSON files.
It displays results using Grafana and InfluxDB time series database.

It can import developers affiliations from [cncf/gitdm](https://github.com/cncf/gitdm).

# Compilation

Uses GNU `Makefile`:
- `make check` - to apply gofmt, goimports, golint, go vet.
- `make` to compile static binaries: `structure`, `gha2db`, `db2influx`, `gha2db_sync`, `runq`, `z2influx`, `import_affs`, `annotations`.
- `make install` - to install binaries, this is needed for cron job.
- `make clean` - to clean binaries
- `make test` - to execute non-DB tests
- `GHA2DB_PROJECT=kubernetes PG_DB=dbtest PG_PASS=pwd IDB_DB=dbtest IDB_PASS=pwd make dbtest` - to execute DB tests.

All `*.go` files in project root directory are common library `gha2db` for all go executables.
All `*_test.go` and `test/*.go` are Go test files, that are used only for testing.

To run tools locally (without install) prefix them with `GHA2DB_LOCAl=1 `.

# Usage:

Local:
- `make`
- `ENV_VARIABLES GHA2DB_LOCAl=1 ./gha2db YYYY-MM-DD HH YYYY-MM-DD HH [org [repo]]`.

Installed:
- `make`
- `sudo make install`
- `ENV_VARIABLES gha2db YYYY-MM-DD HH YYYY-MM-DD HH [org [repo]]`.


You can use already populated Postgres dump: [Kubernetes Psql dump](https://devstats.cncf.io/gha.sql.xz) (more than 380 Mb, more than 7,5Gb uncompressed)

There is also a dump for `cncf` org: [CNCF Psql dump](https://cncftest.io/cncf.sql.xz) (less than 900 kb, about 8,5 Mb uncompressed, data from 2017-03-01)

First two parameters are date from:
- YYYY-MM-DD
- HH

Next two parameters are date to:
- YYYY-MM-DD
- HH

Both next two parameters are optional:
- org (if given and non-empty '' then only return JSONs matching given org). You can also provide a comma-separated list of orgs here: 'org1,org2,org3'.
- repo (if given and non-empty '' then only return JSONs matching given repo). You can also provide a comma-separated list of repos here: 'repo1,repo2'.

Org/Repo filtering:
- You can filter only by org by passing for example 'kubernetes' for org and '' for repo or skipping repo.
- You can filter only by repo, You need to pass '' as org and then repo name.
- You can return all JSONs by skipping both params.
- You can provide both to observe only events from given org/repo.
- You can list exact full repository names to run on: use `GHA2DB_EXACT=1` to process only repositories listed as "orgs" parameter, by their full names, like for example 3 repos: "GoogleCloudPlatform/kubernetes,kubernetes,kubernetes/kubernetes".

# Configuration

You can tweak `devstats` tools by environment variables:
- Set `GHA2DB_ST` environment variable to run single threaded version.
- Set `GHA2DB_JSON` to save single events JSONs in [jsons/](https://github.com/cncf/devstats/blob/master/jsons/) directory.
- Set `GHA2DB_NODB` to skip DB processing at all (if `GHA2DB_JSON` not set it will parse all data from GHA, but do nothing with it).
- Set `GHA2DB_DEBUG` set to 1 to see output for all events generated, set to 2 to see all SQL query parameters.
- Set `GHA2DB_QOUT` to see all SQL queries.
- Set `GHA2DB_MGETC` to "y" to assume "y" for `getchar` function (for example to answer "y" to `structure`'s Continue? question).
- Set `GHA2DB_CTXOUT` to display full environment context.
- Set `GHA2DB_NCPUS` to positive numeric value, to override the number of CPUs to run, this overwrites `GHA2DB_ST`.
- Set `GHA2DB_STARTDT`, to use start date for processing events (when syncing data with an empty database), default `2015-08-06 22:00 UTC`, expects format "YYYY-MM-DD HH:MI:SS".
- Set `GHA2DB_LASTSERIES`, to specify which InfluxDB series use to determine newest data (it will be used to query the newest timestamp), default `'events_h'`.
- Set `GHA2DB_CMDDEBUG` set to 1 to see commands executed, set to 2 to see commands executed and their output, set to 3 to see full exec environment.
- Set `GHA2DB_EXPLAIN` for `runq` tool, it will prefix query select(s) with "explain " to display query plan instead of executing the real query. Because metric can have multiple selects, and only main select should be replaced with "explain select" - we're replacing only downcased "select" statement followed by newline ("select\n" --> "explain select\n")
- Set `GHA2DB_OLDFMT` for `gha2db` tool to make it use old pre-2015 GHA JSONs format (instead of a new one used by GitHub Archives from 2015-01-01).
- Set `GHA2DB_EXACT` for `gha2db` tool to make it process only repositories listed as "orgs" parameter, by their full names, like for example 3 repos: "GoogleCloudPlatform/kubernetes,kubernetes,kubernetes/kubernetes"
- Set `GHA2DB_SKIPLOG` for any tool to skip logging output to `gha_logs` table.
- Set `GHA2DB_LOCAL` for `gha2db_sync` tool to make it prefix call to other tools with "./" (so it will use other tools binaries from the current working directory instead of `/usr/bin/`). Local mode uses "./metrics/{{project}}/" to search for metrics files. Otherwise "/etc/gha2db/metrics/{{project}}/" is used.
- Set `GHA2DB_ANNOTATIONS_YAML` for `annotations` tool, set name of annotation yaml file, default is "metrics/{{project}}/annotations.yaml".
- Set `GHA2DB_METRICS_YAML` for `gha2db_sync` tool, set name of metrics yaml file, default is "metrics/{{project}}/metrics.yaml".
- Set `GHA2DB_GAPS_YAML` for `gha2db_sync` tool, set name of gaps yaml file, default is "metrics/{{project}}/gaps.yaml".
- Set `GHA2DB_MAXLOGAGE` for `gha2db_sync` tool, maximum age of DB logs stored in `gha_logs` table, default "1 week" (logs are cleared in `gha2db_sync` job).
- Set `GHA2DB_TRIALS` for tools that use Postgres DB, set retry periods when "too many connection open" psql error appears, default is "10,30,60,120,300,600" (so 30s, 1min, 2min, 5min, 10min).
- Set `GHA2DB_SKIPTIME` for all tools to skip time output in program outputs (default is to show time).
- Set `GHA2DB_WHROOT`, for webhook tool, default "/hook", must match .travis.yml notifications webhooks.
- Set `GHA2DB_WHPORT`, for webhook tool, default ":1982", (note that webhook listens at 1982, but we are using https via apache proxy, apache listens on https port 2892 and proxy request to http 1982).
- Set `GHA2DB_SKIP_VERIFY_PAYLOAD`, webhook tool, default true, use to skip payload checking and allow manual testing `GHA2DB_SKIP_VERIFY_PAYLOAD=1 ./webhook`.
- Set `GHA2DB_DEPLOY_BRANCHES`, webhook tool, default "master", comma separated list, use to set which branches should be deployed.
- Set `GHA2DB_DEPLOY_STATUSES`, webhook tool, default "Passed,Fixed", comma separated list, use to set which branches should be deployed.
- Set `GHA2DB_DEPLOY_RESULTS`, webhook tool, default "0", comma separated list, use to set which travis ci results should be deployed.
- Set `GHA2DB_DEPLOY_TYPES`, webhook tool, default "push", comma separated list, use to set which event types should be deployed.
- Set `GHA2DB_PROJECT_ROOT`, webhook tool, no default - You have to set it to where the project repository is cloned (usually $GOPATH:/src/devstats).
- Set `GHA2DB_PROJECT`, `gha2db_sync` tool to get per project arguments automaticlly and to set all other config files directory prefixes (for example `metrics/prometheus/`), it reads data from `projects.yaml`.

All environment context details are defined in [context.go](https://github.com/cncf/devstats/blob/master/context.go), please see that file for details (You can also see how it works in [context_test.go](https://github.com/cncf/devstats/blob/master/context_test.go)).

Examples in this shell script (some commented out, some not):

`time PG_PASS=your_pass ./scripts/gha2db.sh`

# Informations

GitHub archives keep data as Gzipped JSONs for each hour (24 gzipped JSONs per day).
Single JSON is not a real JSON file, but "\n" newline separated list of JSONs for each GitHub event in that hour.
So this is a JSON array in reality.

GihHub archive files can be found here <https://www.githubarchive.org>

For example to fetch 2017-08-03 18:00 UTC can be fetched by:

- wget http://data.githubarchive.org/2017-08-03-18.json.gz

Gzipped files are usually 10-30 Mb in size (single hour).
Decompressed fields are usually 100-200 Mb.

We download this gzipped JSON, process it on the fly, creating the array of JSON events and then each single event JSON matching org/repo criteria is saved in [jsons](https://github.com/cncf/devstats/blob/master/jsons/) directory as `N_ID.json` where:
- N - given GitHub archive''s JSON hour as UNIX timestamp.
- ID - GitHub event ID.

Once saved, You can review those JSONs manually (they're pretty printed).

# Multithreading

For example <http://cncftest.io> server has 48 CPU cores.
It will just process 48 hours in parallel.
It detects the number of available CPUs automatically.
You can use `GHA2DB_ST` environment variable to force single threaded version.

# Results (JSON)

Usually, there are about 25000 GitHub events in a single hour in Jan 2017 (for July 2017 it is 40000).
Average seems to be from 15000 to 60000.

1) Running this program on 5 days of data with org `kubernetes` (and no repo set - which means all kubernetes repos):
- Takes: 10 minutes 50 seconds.
- Generates 12002 JSONs with summary size 165 Mb (each JSON is a single GitHub event).
- To do so it processes about 21 Gb of data.

2) Running this program 1 month of data with org `kubernetes` (and no repo set - which means all kubernetes repos).
June 2017:
- Takes: 61 minutes 26 seconds.
- Generates 60773 JSONs with summary size 815 Mb.
- To do so it processes about 126 Gb of data.

3) Running this program 3 hours of data with no filters.
2017-07-05 hours: 18, 19, 20:
- Takes: 55 seconds.
- Generates 168683 JSONs with summary size 1.1 Gb.
- To do so it processes about 126 Gb of data.

Taking all events from a single day is 5 minutes 50 seconds (2017-07-28):
- Generates 1194599 JSON files (1.2M)
- Takes 7 Gb of disc space

There is a big file containing all Kubernetes events JSONs from Aug 2017 concatenated and xzipped: [K8s August 2017](https://cncftest.io/k8s_201708.json.xz).

Please note that this is not a correct JSON, it contains files separated by line `JSON: jsons/filename.json` - that says what was the original JSON filename. This file is 16.7M xzipped, but 1.07G uncompressed.

Please also note that JSON for 2016-10-21 18:00 is broken, so running this command will produce no data. The code will output error to logs and continue. Always examine `errors.txt` from `kubernetes/kubernetes*.sh` script.

This will log error and process no JSONs:
- `./gha2db 2016-10-21 18 2016-10-21 18 'kubernetes,kubernetes-client,kubernetes-incubator,kubernetes-helm'`.

1) Running on all Kubernetes org since the beginning of kubernetes:
- Takes about 2h15m.
- Database dump is 7.5 Gb, XZ compressed dump is ~400 Mb
- Note that those counts include historical changes to objects (for example single issue can have multiple entries with a different state on different events)
- Completed [dump](https://devstats.cncf.io/gha.sql.xz).

# PostgreSQL database setup

Detailed setup instructions are here (they use already populated postgres dump):
- [Mac >= 10.12](https://github.com/cncf/devstats/blob/master/INSTALL_MAC.md)
- [Linux Ubuntu 16 LTS](https://github.com/cncf/devstats/blob/master/INSTALL_UBUNTU16.md)
- [Linux Ubuntu 17](https://github.com/cncf/devstats/blob/master/INSTALL_UBUNTU17.md)

In short for Ubuntu like Linux:

- apt-get install postgresql 
- sudo -i -u postgres
- psql
- create database gha;
- create user gha_admin with password 'your_password_here';
- grant all privileges on database "gha" to gha_admin;
- alter user gha_admin createdb;
- go get github.com/lib/pq
- PG_PASS='pwd' ./structure
- psql gha

`structure` script is used to create Postgres database schema.
It gets connection details from environmental variables and falls back to some defaults.

Defaults are:
- Database host: environment variable PG_HOST or `localhost`
- Database port: PG_PORT or 5432
- Database name: PG_DB or 'gha'
- Database user: PG_USER or 'gha_admin'
- Database password: PG_PASS || 'password'
- Database SSL: PG_SSL || 'disable'
- If You want it to generate database indexes set `GHA2DB_INDEX` environment variable
- If You want to skip table creations set `GHA2DB_SKIPTABLE` environment variable (when `GHA2DB_INDEX` also set, it will create indexes on already existing table structure, possibly already populated)
- If You want to skip creating DB tools (like views and functions), use `GHA2DB_SKIPTOOLS` environment variable.

It is recommended to create structure without indexes first (the default), then get data from GHA and populate array, and finally add indexes. To do do:
- `time PG_PASS=your_password ./structure`
- `time PG_PASS=your_password ./scripts/gha2db.sh`
- `time GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 PG_PASS=your_password ./structure` (will take some time to generate indexes on populated database)

Typical internal usage:
`time GHA2DB_INDEX=1 PG_PASS=your_password ./structure`

Alternatively, you can use [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql) to create database structure.

You can also use already populated Postgres dump: [Kubernetes Psql dump](https://devstats.cncf.io/gha.sql.xz)

# Database structure

You can see database structure in [structure.go](https://github.com/cncf/devstats/blob/master/structure.go)/[structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql).

The main idea is that we divide tables into 2 groups:
- const: meaning that data in this table is not changing in time (is saved once)
- variable: meaning that data in those tables can change between GH events, and GH event_id is a part of this tables primary key.

List of tables:
- `gha_actors`: const, users table
- `gha_actors_emails`: const, holds one or more email addresses for actors, this is filled by `./import_affs` tool.
- `gha_actors_affiliations`: const, holds one or more company affiliations for actors, this is filled by `./import_affs` tool.
- `gha_assets`: variable, assets
- `gha_branches`: variable, branches data
- `gha_comments`: variable (issue, PR, review)
- `gha_commits`: variable, commits
- `gha_companies`: const, companies, this is filled by `./import_affs` tool.
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
- `gha_teams`: variable, teams
- `gha_teams_repositories`: variable, teams repositories connections
- `gha_logs`: this is a table that holds all tools logs (unless `GHA2DB_SKIPLOG` is set)
- `gha_texts`: this is a compute table, that contains texts from comments, commits, issues and pull requests, updated by `gha2db_sync` and structure tools
- `gha_issues_pull_requests`: this is a compute table that contains PRs and issues connections, updated by `gha2db_sync` and structure tools
- `gha_issues_events_labels`: this is a compute table, that contains shortcuts to issues labels (for metrics speedup), updated by `gha2db_sync` and structure tools

There is some data duplication in various columns. This is to speedup metrics processing.
Such columns are described as "dup columns" in [structure.go](https://github.com/cncf/devstats/blob/master/structure.go)
Such columns are prefixed by "dup_". They're usually not null columns, but there can also be null able columns - they start with "dupn_".

There is a standard duplicate event structure consisting of (dup_type, dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_created_at), I'll call it `eventd`

Duplicated columns:
- dup_actor_login, dup_repo_name in `gha_events` are taken from `gha_actors` and `gha_repos` to save joins.
- `eventd` on `gha_payloads`
- Just take a look at "dup_" and "dupn_" fields on all tables.

# Adding columns to existing database

- alter table table_name add col_name col_def;
- update ...
- alter table table_name alter column col_name set not null;

# JSON examples

There are examples of all kinds of GHA events JSONs in [./analysis](https://github.com/cncf/devstats/blob/master/analysis/) directory.
There is also a file [analysis/analysis.txt](https://github.com/cncf/devstats/blob/master/analysis/analysis.txt) that describes JSON structure analysis.

It was used very intensively during a development of SQL table structure.

All JSON and TXT files starting with "old_" and txt files starting with "old_" are the result of pre-2015 GHA JSONs structure analysis.

All JSON and TXT files starting with "new_" and txt files starting with "new_" are the result of new 2015+ GHA JSONs structure analysis.

To Run JSON structure analysis for either pre or from 2015 please do:
- `analysis/analysis_from2015.sh`.
- `analysis/analysis_pre2015.sh`.

Both those tools require Ruby. This tool was originally in Ruby, and there is no sense to rewrite it in Go because:
- It uses a very dynamic code, reflection and code evaluation as provided by properties list from the command line.
- It is used only during implementation (first post 2015 version, and now for pre-2015).
- It would be at least 10x longer and more complicated in Go, and probably not really faster because it would have to use reflection too.
- This kind of code will be very hard to read in Go.

# Running on Kubernetes

Kubernetes consists of 4 different orgs (from 2014-06-01), so to gather data for Kubernetes You need to provide them comma separated.

Before 2015-08-06 Kubernetes is in `GoogleCloudPlatform/kubernetes` or just few kubernetes repos without org. To process them You need to use special list mode `GHA2DB_EXACT`.

And finally before 2015-01-01 GitHub used different JSONs format. To process them You have to use `GHA2DB_OLDFMT` mode.

For example June 2017:
- `time PG_PASS=pwd ./gha2db 2017-06-01 0 2017-07-01 0 'kubernetes,kubernetes-incubator,kubernetes-client,kubernetes-helm'`

To process kubernetes all time just use `kubernetes/kubernetes.sh` script. Like this:
- `time PG_PASS=pwd ./kubernetes/kubernetes.sh`.

# Metrics tool
There is a tool `runq`. It is used to compute metrics saved in `*.sql` files.
Please be careful when creating metric files, that needs to support `explain` mode (please see `GHA2DB_EXPLAIN` environment variable description):

Because metric can have multiple selects, and only main select should be replaced with "explain select" - we're replacing only lower case "select" statement followed by new line.
Exact match "select\n". Please see [metrics/{{project}}/reviewers.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/reviewers.sql) to see how it works.

Metrics are in [./metrics/{{project}}/](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/) directory.

This tool takes at least one parameter - sql file name.

Typical usages:
- `time PG_PASS='password' ./runq metrics/{{project}}/metric.sql`

Some SQLs files require parameter substitution (like all metrics used by Grafana).

They usually have `'{{from}}'` and `'{{to}}'` parameters, to run such files do:
- `time PG_PASS='password' ./runq metrics/{{project}}/metric.sql '{{from}}' 'YYYY-MM-DD HH:MM:SS' '{{to}}' 'YYYY-MM-DD HH:MM:SS' '{{n}}' 1.0`

You can also change any other value, just note that parameters after SQL file name are pairs: (`value_to_replace`, `replacement`).

# Sync tool

When You have imported all data You need - it needs to be updated periodically.
GitHub archive generates new file every hour.

Use `gha2db_sync` tool to update all Your data.

Example call:
- `GHA2DB_PROJECT=kubernetes PG_PASS='pwd' IDB_PASS='pwd' ./gha2db_sync`
- Add `GHA2DB_RESETIDB` environment variable to rebuild InfluxDB stats instead of update since the last run
- Add `GHA2DB_SKIPIDB` environment variable to skip syncing InfluxDB (so it will only sync Postgres DB)
- Add `GHA2DB_SKIPPDB` environment variable to skip syncing Postgres (so it will only sync Influx DB)

Sync tool uses [gaps.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/gaps.yaml), to prefill some series with zeros. This is needed for metrics (like SIG mentions or PRs merged) that return multiple rows, depending on data range.
Sync tool read project definition from [projects.yaml](https://github.com/cncf/devstats/blob/master/projects.yaml)

# Cron

You can have multiple projects running on the same machine (like `GHA2DB_PROJECT=kubernetes` and `GHA2DB_PROJECT=prometheus`) running in a slightly different time window.
Both kubernetes and prometheus projects are using tags on their dashboards.
You should choose only one project on production, and only import given projects dashboards. Each projects should run on a separate server on production.
Example cron tab file (containing entries for all projects): [crontab.entry](https://github.com/cncf/devstats/blob/master/metrics/crontab.entry)

To install cron job please check "cron" section:

- [Mac](https://github.com/cncf/devstats/blob/master/INSTALL_MAC.md)
- [Linux Ubuntu 16 LTS](https://github.com/cncf/devstats/blob/master/INSTALL_UBUNTU16.md)
- [Linux Ubuntu 17](https://github.com/cncf/devstats/blob/master/INSTALL_UBUNTU17.md)

# Developers affiliations

You need to get [github_users.json](https://raw.githubusercontent.com/cncf/gitdm/master/github_users.json) file from [CNCF/gitdm](https://github.com/cncf/gitdm).

To generate this file follow instructions on cncf/gitdm, or just get the newest version.

This file contains all GitHub user name - company affiliations found by `cncf/gitdm`.

To load it into our database use:
- `PG_PASS=pwd ./kubernetes/import_affs.sh`

# Repository groups

There are some groups of repositories that can be used to create metrics for lists of repositories.
They are defined in [scripts/kubernetes/repo_groups.sql](https://github.com/cncf/devstats/blob/master/scripts/kubernetes/repo_groups.sql).
Repository group is defined on `gha_repos` table using `repo_group` value.

To setup default repository groups:
- `PG_PASS=pwd ./kubernetes/setup_repo_groups.sh`.

This is a part of `kubernetes/kubernetes.sh` script and [kubernetes psql dump](https://devstats.cncf.io/gha.sql.xz) already has groups configured.

# Grafana output

You can visualise data using Grafana, see [grafana/](https://github.com/cncf/devstats/blob/master/grafana/) directory:

Grafana install instruction are here:
- [Mac](https://github.com/cncf/devstats/blob/master/INSTALL_MAC.md)
- [Linux Ubuntu 16 LTS](https://github.com/cncf/devstats/blob/master/INSTALL_UBUNTU16.md)
- [Linux Ubuntu 17](https://github.com/cncf/devstats/blob/master/INSTALL_UBUNTU17.md)

# To drop & recreate InfluxDB:
- `IDB_PASS='idb_password' ./grafana/influxdb_recreate.sh`
- `GHA2DB_PROJECT=kubernetes GHA2DB_RESETIDB=1 PG_PASS='pwd' IDB_PASS='pwd' ./gha2db_sync`

Or automatically: drop & create Influx DB, update Postgres DB since the last run, full populate InfluxDB, start syncer every 30 minutes:
- `GHA2DB_PROJECT=kubernetes IDB_PASS=pwd PG_PASS=pwd ./reinit_all.sh`

# Alternate solution with Docker:

Note that this is an old solution that worked, but wasn't tested recently.

- Start Grafana using `GRAFANA_PASS='password' grafana/grafana_start.sh` to install Grafana & InfluxDB as docker containers (this requires Docker).
- Start InfluxDB using `IDB_PASS='password' ./grafana/influxdb_setup.sh gha`, this requires Docker & previous command succesfully executed.
- To cleanup Docker Grafana image and start from scratch use `./grafana/docker_cleanup.sh`. This will not delete Your grafana config because it is stored in local volume `/var/lib/grafana`.
- To recreate all Docker Grafana/InfluxDB stuff from scratch do: `GRAFANA_PASS='' IDB_PASS='' GHA2DB_RESETIDB=1 PG_PASS='' IDB_PASS='' ./grafana/reinit.sh`

# Manually feeding InfluxDB & Grafana:

Feed InfluxDB using:
- `PG_PASS='psql_pwd' IDB_PASS='influxdb_pwd' ./db2influx sig_metions_data metrics/kubernetes/sig_mentions.sql '2017-08-14' '2017-08-21' d`
- The first parameter is used as exact series name when metrics query returns single row with single column value.
- First parameter is used as function name when metrics query return mutiple rows, each with >= 2 columns. This function receives data row and the period name and should return series name and value(s).
- The second parameter is a metrics SQL file, it should contain time conditions defined as `'{{from}}'` and `'{{to}}'`.
- Next two parameters are date ranges.
- The last parameter can be h, d, w, m, q, y (hour, day, week, month, quarter, year).
- This tool uses environmental variables starting with `IDB_`, please see `context.go`, `idb_conn.go` and `cmd/db2influx/db2influx.go` for details.
- `IDB_` variables are exactly the same as `PG_` to set host, database, user name, password.
- There is also `z2influx` tool. It is used to fill given series with zeros. Typical usage: `./z2influx 'series1,series2' 2017-01-01 2018-01-01 w` - will fill all weeks from 2017 with zeros for series1 and series2.
- `annotations` tool adds variuos data annotations that can be used in Grafana charts. It uses [annotations.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/annotations.yaml) file to define them, syntax is self describing. 
- `idb_tags` tool used to add InfluxDB tags on some specified series. Those tags are used to populate Grafana template drop-down values and names. This is used to auto-populate Repository groups drop down, so when somebody adds new repository group - it will automatically appear in the drop-down.
- `idb_tags` uses [idb_tags.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/idb_tags.yaml) file to configure InfluxDB tags generation.
- `idb_backup` is used to backup/restore InfluxDB. Full renenerate of InfluxDB takes about 12 minutes. To avoid downtime when we need to rebuild InfluxDB - we can generate new InfluxDB on `test` database and then if succeeded, restore it on `gha`. Downtime will be about 2 minutes.

# To check results in the InfluxDB:
- influx (or just influx -database gha -username gha_admin -password your_pwd)
- auth (gha_admin/influxdb_pwd)
- use gha
- precision rfc3339
- select * from reviewers
- select count(*) from reviewers
- show tag keys
- show field keys
- show series

# To drop data from InfluxDB:
- drop measurement reviewers
- drop series from reviewers

# Grafana dashboards
Grafana allows saving dashboards to JSON files.
There are few defined dashboards kubernetes, prometheus, opentracing directories:
- [grafana/dashboards/kubernetes/](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/).
- [grafana/dashboards/prometheus/](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/).
- [grafana/dashboards/opentracing/](https://github.com/cncf/devstats/blob/master/grafana/dashboards/opentracing/).

Metrics are described in [README](https://github.com/cncf/devstats/blob/master/README.md) in `Grafana dashboards` and `Adding new metrics` sections.

# To enable SSL Grafana:

Please see instructions [here](https://github.com/cncf/devstats/blob/master/SSL.md)

# Grafana anonymous login

Please see instructions [here](https://github.com/cncf/devstats/blob/master/GRAFANA.md)

# Continuous deployment

There is a tool [webhook](https://github.com/cncf/devstats/blob/master/metrics/cmd/webhook/webhook.go) that is used to make deployments on successful build webhooks sent by Travis CI.

Details [here](https://github.com/cncf/devstats/blob/master/metrics/CONTINUOUS_DEPLOYMENT.md).

# Benchmarks
Benchmarks were executed on historical Ruby version and current Go version.

Please see [Historical benchmarks](https://github.com/cncf/devstats/blob/master/BENCHMARK.md)

# Testing

Please see [Tests](https://github.com/cncf/devstats/blob/master/TESTING.md)

