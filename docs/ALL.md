### [CONTRIBUTING](https://github.com/cncf/devstats/blob/master/CONTRIBUTING.md)
# Contributing to devstats
If You see any error, or if You have suggestion please create [issue and/or PR](https://github.com/cncf/devstats).

# Coding standards
- Please follow coding standards required for Go language.
- This is checked during the `make` step which calls the following static analysis/lint tools: `fmt lint imports vet const usedexports`.
- When adding new functionality please add test coverage please that will be executed by `make test`.
- If adding new database functionality and/or new metrics, please add new test covergage that will be executed by:
- `GHA2DB_PROJECT=kubernetes IDB_HOST='...' PG_PASS='...' IDB_PASS='...' ./dbtest.sh`.
- New metrics test coverage should be added in `metrics_test.go`.

# Working locally
Please see [Development](https://github.com/cncf/devstats/blob/master/DEVELOPMENT.md).

# Testing
Please see [Tests](https://github.com/cncf/devstats/blob/master/TESTING.md).

# Vulnerabilities
Please use GitHub [issues](https://github.com/cncf/devstats/issues) to report any vulnerability found.

# Adding new project
To add new project follow [adding new project](https://github.com/cncf/devstats/blob/master/ADDING_NEW_PROJECT.md) instructions.
### [ADDING_NEW_PROJECT](https://github.com/cncf/devstats/blob/master/ADDING_NEW_PROJECT.md)
# Adding new project

This file describes how to add new project on the test server.

## To add new project on the production (when already added on the test), you should use automatic deploy script:

- Make sure that you have Postgres database backup generated on the test server (this happens automatically on full deploy and nightly).
- Make sure you have Grafana DB dumps available on the test server by running `./grafana/copy_grafana_dbs.sh`.
- Commit to `production` branch with `[deploy]` in the commit message. Automatic deploy will happen. After successful deploy start Grafana `./grafana/newproj/grafana_start.sh &`.
- Or manually run `PG_PASS=... IDB_PASS=... IDB_PASS_SRC=... IDB_HOST=... IGET=1 GET=1 ./devel/deploy_all.sh` script with correct env variables.
- Go to `https://newproject.devstats.cncf.io` and change Grafana, InfluxDB and PostgreSQL passwords (default deploy copies database from the test server, so it has test server credentials initially).
- Reimport Home dashboard (which now contains link to a new project) on all existing projects.

## To add a new project on the test server follow instructions:

- Do not commit changes until all is ready, or commit with `[no deploy]` in the commit message.
- Add project entry to `projects.yaml` file. Find projects orgs, repos, select start date, eventually add test coverage for complex regular expression in `regexp_test.go`.
- To identify repo and/or org name changes, date ranges for entrire projest use `util_sql/(repo|org)_name_changes_bigquery.sql` replacing name there.
- Main repo can be empty `''` - in this case only two annotations will be added: 'start date - CNCF join date' and 'CNCF join date - now".
- CNCF join dates are listed here: https://github.com/cncf/toc#projects.
- Update projects list files: `devel/all_prod_dbs.txt devel/all_prod_projects.txt devel/all_test_dbs.txt devel/all_test_projects.txt` and project icon type `devel/get_icon_type.sh`.
- Add this new project config to 'All' project in `projects.yaml all/psql.sh grafana/dashboards/all/dashboards.json scripts/all/repo_groups.sql devel/calculate_hours.sh`.
- Add entire new project as a new repo group in 'All' project.
- Add new domain for the project: `projectname.cncftest.io`. If using wildcard domain like `*.devstats.cncf.io` - this step is not needed.
- Add Google Analytics (GA) for the new domain and update /etc/grafana.projectname/grafana.ini with its `UA-...`.
- Review `grafana/copy_artwork_icons.sh apache/www/copy_icons.sh grafana/create_images.sh grafana/change_title_and_icons_all.sh` - maybe you need to add special case. Icon related scripts are marked 'ARTWORK'.
- Copy setup scripts and then adjust them: `cp -R oldproject/ projectname/`, `vim projectname/*`. Update automatic deploy script: `./devel/deploy_all.sh`.
- Copy `metrics/oldproject` to `metrics/projectname`. Update `./metrics/projectname/*_vars.yaml` files.
- `cp -Rv scripts/oldproject/ scripts/projectname`, `vim scripts/projectname/*`.
- `cp -Rv grafana/oldproject/ grafana/projectname/` and then update files. Usually `%s/oldproject/newproject/g|w|next`. Exception is the new projects Grafana port number.
- `cp -Rv grafana/dashboards/oldproject/ grafana/dashboards/projectname/` and then update files.  Use `devel/mass_replace.sh` script, it contains some examples in the comments.
- Something like this: "MODE=ss0 FROM='"oldproject"' TO='"newproject"' FILES=`find ./grafana/dashboards/newproject -type f -iname '*.json'` ./devel/mass_replace.sh".
- Update `grafana/dashboards/proj/dashboards.json` for all already existing projects, add new project using `devel/mass_replace.sh` or `devel/replace.sh`.
- For example: `MODE=ss0 FROM=`cat FROM` TO=`cat TO` FILES=`find ./grafana/dashboards/ -type f -iname 'dashboards.json'` ./devel/mass_replace.sh` with `FROM` containing old links and `TO` containing new links.
- Update `partials/projects.html`.
- Update Apache proxy and SSL files `apache/www/index_* apache/*/sites-enabled/* apache/*/sites.txt` files.
- Run deply all script: `PG_PASS=... IDB_PASS=... IDB_HOST=... ./devel/deploy_all.sh`. If succeeded `make install`.
- You can also deploy automatically from webhook (even on the test server), but it takes very long time and is harder to debug, see [continuous deployment](https://github.com/cncf/devstats/blob/master/CONTINUOUS_DEPLOYMENT.md).
- Open `newproject.cncftest.io` login with admin/admin, change the default password and follow instructions from `GRAFANA.md`.
- Import `grafana/dashboards/proj/dashboards.json` dashboard on all remaining projects.
- Import all new projects dashboards from `grafana/dashboards/newproject/*.json`, then finally: `grafana/copy_grafana_dbs.sh`
- Final deploy script is: `./devel/deploy_all.sh`. It should do all deployment automatically on the prod server. Follow all code from this script (eventually run some parts manually, the final version should do full deploy OOTB).
### [ISSUE_TEMPLATE](https://github.com/cncf/devstats/blob/master/ISSUE_TEMPLATE.md)
Please make sure that You follow instructions from [CONTRIBUTING](https://github.com/cncf/devstats/blob/master/CONTRIBUTING.md)
### [BENCHMARK](https://github.com/cncf/devstats/blob/master/BENCHMARK.md)
# Benchmarks

Please note that those benchmark informations are very old.

Please note that Ruby version was removed. It was slower, and Kubernetes community prefer tools written in Go.

Postgresql was faster than MySQL, so it was only supported in a dropped Ruby version. Go version uses Postgres.

Here are historical results of benchmarks Go & Ruby tools:

# gha2db tool benchmarks

We're trying 3 versions:
- Ruby on Postgres.
- Ruby on MySQL.
- Go on Postgres.

On 2 data sets:
- All kubernetes GHA events (orgs `kubernetes`, `kubernetes-incubator` and `kubernetes-client`) on single month `2017-07-01` - `2017-08-01`.
- All GHA events (no org/repo filter) on 2 days `2017-08-01` - `2017-08-03` (Tue and Wed).

Columns:
- `Benchmark` - benchmark name.
- `Events` - number of GHA events created. Note that for `All` we have 2.5M events in just 2 days, while for only Kubernetes we have 66K events in a month.
- `Real time` - time it took to compute.
- `User time` - time it took to compute on all CPUs (so this is the time it *would* take on single CPU machine).
- `Parallelism` - this is the ratio of `User time` to `Real time` - parallelism factor.
- `Range` - length of data processed.

And final run for Kubernetes for all `2015-08-06` - `2017-08-26` using Go version of `gha2db`:
- `time PG_PASS='...' PG_DB='test' ./gha2db 2015-08-06 0 2017-08-26 0 'kubernetes,kubernetes-incubator,kubernetes-client'`

Outputs 1200426 GHA events in:
```
real  112m6.604s --> 6726s
user  1718m21.020s --> 103101s
sys 99m43.964s
```

Results Table:

| Benchmark          | Events      | Real time   | User time   | Parallelism | Range    |
|--------------------|:-----------:|------------:|------------:|------------:|---------:|
| K8s Go / Psql      | 65851       | 5m5.3s      | 81m44.1s    | 16.06x      | 1 month  |
| K8s Ruby / Psql    | 65851       | 63m26.817s  | 68m25.120s  | 1.078x      | 1 month  |
| K8s Ruby / MySQL   | 65851       | 66m13.291s  | 69m45.604s  | 1.053x      | 1 month  |
| All Go / Psql      | 2550663     | 6m4.652s    | 37m10.932s  | 6.12x       | 2 days   |
| All Ruby / Psql    | 2550663     | 45m16.238s  | 50m19.916s  | 1.118x      | 2 days   |
| All Ruby / MySQL   | 2550663     | 46m55.949s  | 40m43.796s  | 0.868x      | 2 days   |
| Full K8s Go / Psql | 1200426     | 1h52m6.6s   | 26h38m21s   | 15.33x      | ~2 years |

# Results

When processing only Kubernetes events, we still need to download, decompress, parse all JSON and select only those with specific org.

This is lightning fast in Go, while terribly slow in Ruby.

Ruby is not really multi-threaded (Ruby MRI), it uses GIL, and essentially it is just single threaded.

We can see max parallelism ratio about 1.11x which mean that even with 48 CPU cores, current Ruby implementation can make use of 1.11 cores.

Links:
- [Ruby threads not really use multiple CPUs](https://stackoverflow.com/questions/56087/does-ruby-have-real-multithreading)
- `For true concurrency having more then 2 cores or 2 processors is required - but it may not work if implementation is single-threaded (such as the MRI).`:
- [Ruby threads in parallel](https://stackoverflow.com/questions/2428140/how-do-i-run-two-threads-in-ruby-at-the-same-time)
- [Ruby interpreter GIL](https://en.wikipedia.org/wiki/Global_interpreter_lock)
- [JRuby](https://en.wikipedia.org/wiki/JRuby):
```
JRuby has the significant architectural advantage to be able to leverage JVM threads without being constrained by a global interpreter lock (similarly to Rubinius), therefore achieving full parallelism within a process, which Ruby MRI cannot achieve despite leveraging OS threads.
```

Seems like only `JRuby` implementation has real MT processing:
```
Remember that only in JRuby threads are truly parallel (other interpreters implement GIL).
```

So Go will kill Ruby all the time! It is about 10x - 15x faster than Ruby on average.

One word: Go version can import all GitHub archives data (not discarding anything) for all Kubernetes orgs/repos, from the beginning on GitHub 2015-08-06 in about 2 hours!

We can also see that MySQL is very slightly slower that Postgres (but this is just for inserting data, without indexes defined yet).
MySQL is a lot slower on metrics/queries - but this is not checked in this benchmark.

# db2influx/gha2db_sync tools benchmarks

To benchmark db2influx we're just running a command that regenerates all metrics.

This is done automatically by `sync`/`sync.rb` tool that just call `db2influx`/`db2influx.rb` for all time range (when `GHA2DB_RESETIDB` env is set).

This also updates Postgres DB (since last run) using `gha2db`/`gha2db.rb`, so we need to run it once, to make sure no updates are needed.

And then we can start benchmark in another run (it will only recompute all InfluxDB time-series then).

- Go version: `time GHA2DB_RESETIDB=1 PG_PASS='...' IDB_PASS='...' PG_DB=test IDB_DB=test ./sync_go.sh`
```
real  1m28.336s
user  1m54.352s
sys 1m11.860s
```
- Ruby version: `time GHA2DB_PSQL=1 GHA2DB_RESETIDB=1 PG_PASS='...' IDB_PASS='...' PG_DB=test IDB_DB=test ./sync_ruby.sh`
```
real  1m46.342s
user  0m51.488s
sys 0m27.408s
```

| Benchmark           | Real time   | User time   | Parallelism | Range    |
|---------------------|------------:|------------:|------------:|---------:|
| All InfluxDB / Go   | 1m28.336s   | 1m54.352s   | 1.29x       | ~2 years |
| All InfluxDB / Ruby | 1m46.342s   | 0m51.488s   | 0.484x      | ~2 years |

We can see that this task is dominated by query Postgres time, so it is less important which programming language is used to do queries.

We can see that Ruby is very slightly slower.

Plase note that this regenerates ALL InfluxDB data for 2 years and is < 2 minutes.

Generating index takes < 3 minutes.

In a typical case it will only add new time-series since last run + eventually process single new GHA hour (since last run). It usually takes less than minute in both languages.

### [USAGE](https://github.com/cncf/devstats/blob/master/USAGE.md)
# GitHub Archives to Postgres, InfluxDB, Grafana

Author: Łukasz Gryglicki <lukaszgryglick@o2.pl>

# Implemented in two languages (historcally)

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

It also clones all git repos to analyse all commits files.

# Compilation

Uses GNU `Makefile`:
- `make check` - to apply gofmt, goimports, golint, errcheck, usedexports, go vet and possibly other tools.
- `make` to compile static binaries: `structure`, `runq`, `gha2db`, `db2influx`, `z2influx`, `gha2db_sync`, `import_affs`, `annotations`, `idb_tags`, `idb_backup`, `webhook`, `devstats`, `get_repos`, `merge_pdbs`, `idb_vars`, `pdb_vars`, `replacer`, `ghapi2db`.
- `make install` - to install binaries, this is needed for cron job.
- `make clean` - to clean binaries
- `make test` - to execute non-DB tests
- `GHA2DB_PROJECT=kubernetes PG_DB=dbtest PG_PASS=pwd IDB_HOST="localhost" IDB_DB=dbtest IDB_PASS=pwd make dbtest` - to execute DB tests.

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
- You can filter only by repo, you need to pass '' as org and then repo name.
- You can return all JSONs by skipping both params.
- You can provide both to observe only events from given org/repo.
- You can list exact full repository names to run on: use `GHA2DB_EXACT=1` to process only repositories listed as "orgs" parameter, by their full names, like for example 3 repos: "GoogleCloudPlatform/kubernetes,kubernetes,kubernetes/kubernetes".
- Without GHA2DB_EXACT flag only full names like "a/b,x/y" can be treated as exact full repository names, names without "/" are treated either as orgs or as repositories.

# Broken githubarchives JSON file
- For 2017-11-08 01:00:00 githubarchive JSON contains an error.

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
- Set `GHA2DB_OLDFMT` for `gha2db` tool to make it use old pre-2015 GHA JSONs format (instead of a new one used by GitHub Archives from 2015-01-01). It is usable for GH events starting from 2012-07-01.
- Set `GHA2DB_EXACT` for `gha2db` tool to make it process only repositories listed as "orgs" parameter, by their full names, like for example 3 repos: "GoogleCloudPlatform/kubernetes,kubernetes,kubernetes/kubernetes"
- Set `GHA2DB_SKIPLOG` for any tool to skip logging output to `gha_logs` table in `devstats` database.
- Set `GHA2DB_LOCAL` for `gha2db_sync` tool to make it prefix call to other tools with "./" (so it will use other tools binaries from the current working directory instead of `/usr/bin/`). Local mode uses "./metrics/{{project}}/" to search for metrics files. Otherwise "/etc/gha2db/metrics/{{project}}/" is used.
- Set `GHA2DB_METRICS_YAML` for `gha2db_sync` tool, set name of metrics yaml file, default is "metrics/{{project}}/metrics.yaml".
- Set `GHA2DB_GAPS_YAML` for `gha2db_sync` tool, set name of gaps yaml file, default is "metrics/{{project}}/gaps.yaml". Please use Grafana's "null as zero" instead of using manuall filling gaps. This simplifies metrics a lot.
- Set `GHA2DB_GITHUB_OAUTH` for `annotations` tool, if not set reads from `/etc/github/oauth` file. Set to "-" to force public access. **annotations tool is not using GitHub API anymore, it uses `git_tags.sh` script instead.**
- Set `GHA2DB_MAXLOGAGE` for `gha2db_sync` tool, maximum age of DB logs stored in `devstats`.`gha_logs` table, default "1 week" (logs are cleared in `gha2db_sync` job).
- Set `GHA2DB_TRIALS` for tools that use Postgres DB, set retry periods when "too many connection open" psql error appears, default is "10,30,60,120,300,600" (so 30s, 1min, 2min, 5min, 10min).
- Set `GHA2DB_SKIPTIME` for all tools to skip time output in program outputs (default is to show time).
- Set `GHA2DB_WHROOT`, for webhook tool, default "/hook", must match .travis.yml notifications webhooks.
- Set `GHA2DB_WHPORT`, for webhook tool, default ":1982", (note that webhook listens at 1982, but we are using https via apache proxy, apache listens on https port 2892 and proxy request to http 1982).
- Set `GHA2DB_WHHOST`, for webhook tool, default "127.0.0.1", this is the IP of webhook socket (set to 0.0.0.0 to allow connection from any IP, 127.0.0.1 only allows connections from localhost - this is secure, we use Apache to enable https and proxy requests to webhook tool).
- Set `GHA2DB_SKIP_VERIFY_PAYLOAD`, webhook tool, default true, use to skip payload checking and allow manual testing `GHA2DB_SKIP_VERIFY_PAYLOAD=1 ./webhook`.
- Set `GHA2DB_SKIP_FULL_DEPLOY`, webhook tool, default true, use `GHA2DB_SKIP_FULL_DEPLOY=1` to skip full deploy when commit message contains `[deploy]` - useful for the test server.
- Set `GHA2DB_DEPLOY_BRANCHES`, webhook tool, default "master", comma separated list, use to set which branches should be deployed.
- Set `GHA2DB_DEPLOY_STATUSES`, webhook tool, default "Passed,Fixed", comma separated list, use to set which branches should be deployed.
- Set `GHA2DB_DEPLOY_RESULTS`, webhook tool, default "0", comma separated list, use to set which travis ci results should be deployed.
- Set `GHA2DB_DEPLOY_TYPES`, webhook tool, default "push", comma separated list, use to set which event types should be deployed.
- Set `GHA2DB_PROJECT_ROOT`, webhook tool, no default - you have to set it to where the project repository is cloned (usually $GOPATH:/src/devstats).
- Set `GHA2DB_PROJECT`, `gha2db_sync` tool to get per project arguments automaticlly and to set all other config files directory prefixes (for example `metrics/prometheus/`), it reads data from `projects.yaml`.
- Set `GHA2DB_RESETRANGES`, `gha2db_sync` tool to regenerate past variables of quick range values, this is useful when you add new annotations.
- Set `GHA2DB_REPOS_DIR`, `get_repos` tool to specify where to clone/pull all devstats projects repositories.
- Set `GHA2DB_PROCESS_REPOS`, `get_repos` tool to enable repos clone/pull job.
- Set `GHA2DB_PROCESS_COMMITS`, `get_repos` tool to enable creating/updating "commits SHA - list of files" mapping.
- Set `GHA2DB_PROJECTS_COMMITS`, `get_repos` tool to enable processing commits only on specified projects, format is "projectName1,projectName2,...,projectNameN", default is "" which means to process all projects from `projects.yaml`.
- Set `GHA2DB_TESTS_YAML`, tests `make test`, set main test file, default is "tests.yaml".
- Set `GHA2DB_PROJECTS_YAML`, many tool, set main projects file, default is "projects.yaml", for example `devel/cncf.sh` uses this/
- Set `GHA2DB_EXTERNAL_INFO`, `get_repos` tool to enable displaying external info needed by cncf/gitdm.
- Set `GHA2DB_PROJECTS_OVERRIDE`, `get_repos`, `devstats` tools - for example "-pro1,+pro2" means never sync pro1 and always sync pro2 (even if disabled in `projects.yaml`).
- Set `GHA2DB_EXCLUDE_REPOS`, `gha2db` tool, default "" - comma separated list of repos to exclude, example: "theupdateframework/notary,theupdateframework/other".
- Set `GHA2DB_INPUT_DBS`, `merge_pdbs` tool - list of input databases to merge, order matters - first one will insert on a clean DB, next will do insert ignore (to avoid constraints failure due to common data).
- Set `GHA2DB_OUTPUT_DB`, `merge_pdbs` tool - output database to merge into.
- Set `IDB_MAXBATCHPOINTS`, all Influx tools - set maximum batch size, default 10240.
- Set `GHA2DB_TMOFFSET`, `gha2db_sync` tool - uses time offset to decide when to calculate various metrics, default offset is 0 which means UTC, good offset for USA is -6, and for Poland is 1 or 2
- Set `GHA2DB_IVARS_YAML`, `idb_vars` tool - to set nonstandard `idb_vars.yaml` file.
- Set `GHA2DB_PVARS_YAML`, `pdb_vars` tool - to set nonstandard `pdb_vars.yaml` file.
- Set `GHA2DB_RECENT_RANGE`, `ghapi2db` tool, default '2 hours'. This is a recent period to check open issues/PR to fix their labels and milestones.
- Set `GHA2DB_MIN_GHAPI_POINTS`, `ghapi2db` tool, minimum GitHub API points, before waiting for reset. Default 1 (API point).
- Set `GHA2DB_MAX_GHAPI_WAIT`, `ghapi2db` tool, maximum wait time for GitHub API points reset (in seconds). Default 1s.

All environment context details are defined in [context.go](https://github.com/cncf/devstats/blob/master/context.go), please see that file for details (you can also see how it works in [context_test.go](https://github.com/cncf/devstats/blob/master/context_test.go)).

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

Once saved, you can review those JSONs manually (they're pretty printed).

# Multithreading

For example <http://cncftest.io> server has 48 CPU cores.
It will just process 48 hours in parallel.
It detects the number of available CPUs automatically.
You can use `GHA2DB_ST` environment variable to force single threaded version.

# Results (JSON)

Example: you can generate and save all JSONs for a single day in jsons/ directory by running (all GitHub repos/orgs without filtering):
- `GHA2DB_JSON=1 GHA2DB_NODB=1 ./gha2db 2018-01-02 0 2018-01-02 0`.

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
- [FreeBSD 11 (work in progress)](https://github.com/cncf/devstats/blob/master/INSTALL_FREEBSD.md)

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
- Create `ro_user` via `PG_PASS=... ./devel/create_ro_user.sh`

`structure` script is used to create Postgres database schema.
It gets connection details from environmental variables and falls back to some defaults.

Defaults are:
- Database host: environment variable PG_HOST or `localhost`
- Database port: PG_PORT or 5432
- Database name: PG_DB or 'gha'
- Database user: PG_USER or 'gha_admin'
- Database password: PG_PASS || 'password'
- Database SSL: PG_SSL || 'disable'
- If you want it to generate database indexes set `GHA2DB_INDEX` environment variable
- If you want to skip table creations set `GHA2DB_SKIPTABLE` environment variable (when `GHA2DB_INDEX` also set, it will create indexes on already existing table structure, possibly already populated)
- If you want to skip creating DB tools (like views and functions), use `GHA2DB_SKIPTOOLS` environment variable.

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
- `gha_commits_files`: const, commit files (uses `git` to get each commit's list of files)
- `gha_events_commits_files`: variable, commit files per event with additional event data
- `gha_skip_commits`: const, store invalid SHAs, to skip processing them again
- `gha_companies`: const, companies, this is filled by `./import_affs` tool
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
- `gha_postprocess_scripts`: const, contains list of SQL scripts to run on database after each data sync
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

Table `gha_logs` is special, recently all logs were moved to a separate database `devstats` that contains only this single table `gha_logs`.
This table is still present on all gha databases, it may be used for some legacy actions.

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

Kubernetes consists of 4 different orgs (from 2014-06-01), so to gather data for Kubernetes you need to provide them comma separated.

Before 2015-08-06 Kubernetes is in `GoogleCloudPlatform/kubernetes` or just few kubernetes repos without org. To process them you need to use special list mode `GHA2DB_EXACT`.

And finally before 2015-01-01 GitHub used different JSONs format. To process them you have to use `GHA2DB_OLDFMT` mode. It is usable for GH events starting from 2012-07-01.

For example June 2017:
- `time PG_PASS=pwd ./gha2db 2017-06-01 0 2017-07-01 0 'kubernetes,kubernetes-incubator,kubernetes-client,kubernetes-helm'`

To process kubernetes all time just use `kubernetes/psql.sh` script. Like this:
- `time PG_PASS=pwd ./kubernetes/psql.sh`.

# Check erros

To see if there are any errors please use script: `PG_PASS=... ./devel/get_errors.sh`.

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

For some histograms special format of replace is used (to support quick ranges), they use `{{period:alias.col_name}}`.
To run this in `runq` use:
- `time PG_PASS='password' ./runq metrics/{{project}}/metric.sql qr '1 week,,'` - to specify period ago (like `1week,,`, `3 months,,` etc.).
- `time PG_PASS='password' ./runq metrics/{{project}}/metric.sql qr ',2017-07-16,2017-11-30 10:18:00'` - to specify period date range. 

You can also change any other value, just note that parameters after SQL file name are pairs: (`value_to_replace`, `replacement`).

# Checking projects activity

- Use: `PG_PASS=... PG_DB=allprj ./devel/activity.sh '1 month,,' > all.txt`.
- Example results [here](https://cncftest.io/all.txt) - all CNCF project activity during January 2018, excluding bots.

# Sync tool

When you have imported all data you need - it needs to be updated periodically.
GitHub archive generates new file every hour.

Use `gha2db_sync` tool to update all your data.

Example call:
- `GHA2DB_PROJECT=kubernetes PG_PASS='pwd' IDB_HOST="localhost" IDB_PASS='pwd' ./gha2db_sync`
- Add `GHA2DB_RESETIDB` environment variable to rebuild InfluxDB stats instead of update since the last run
- Add `GHA2DB_SKIPIDB` environment variable to skip syncing InfluxDB (so it will only sync Postgres DB)
- Add `GHA2DB_SKIPPDB` environment variable to skip syncing Postgres (so it will only sync Influx DB)

Sync tool uses [gaps.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/gaps.yaml), to prefill some series with zeros.
This is needed for metrics (like SIG mentions or PRs merged) that return multiple rows, depending on data range.
Please use Grafana's "null as zero" instead of using manuall filling gaps. This simplifies metrics a lot.
Sync tool read project definition from [projects.yaml](https://github.com/cncf/devstats/blob/master/projects.yaml)

You can also use `devstats` tool that calls `gha2db_sync` for all defined projects and also updates local copy of all git repos using `get_repos`.

# Cron

You can have multiple projects running on the same machine (like `GHA2DB_PROJECT=kubernetes` and `GHA2DB_PROJECT=prometheus`) running in a slightly different time window.
Both kubernetes and prometheus projects are using tags on their dashboards.
You should choose only one project on production, and only import given projects dashboards. Each projects should run on a separate server on production.
Example cron tab file (containing entries for all projects): [crontab.entry](https://github.com/cncf/devstats/blob/master/metrics/crontab.entry)

To install cron job please check "cron" section:

- [Mac](https://github.com/cncf/devstats/blob/master/INSTALL_MAC.md)
- [Linux Ubuntu 16 LTS](https://github.com/cncf/devstats/blob/master/INSTALL_UBUNTU16.md)
- [Linux Ubuntu 17](https://github.com/cncf/devstats/blob/master/INSTALL_UBUNTU17.md)
- [FreeBSD 11 (work in progress)](https://github.com/cncf/devstats/blob/master/INSTALL_FREEBSD.md)

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

This is a part of `kubernetes/psql.sh` script and [kubernetes psql dump](https://devstats.cncf.io/gha.sql.xz) already has groups configured.

In an 'All' project (https://all.cncftest.io) repository groups are mapped to individual CNCF projects [scripts/all/repo_groups.sql](https://github.com/cncf/devstats/blob/master/scripts/all/repo_groups.sql):

# Grafana output

You can visualise data using Grafana, see [grafana/](https://github.com/cncf/devstats/blob/master/grafana/) directory:

Grafana install instruction are here:
- [Mac](https://github.com/cncf/devstats/blob/master/INSTALL_MAC.md)
- [Linux Ubuntu 16 LTS](https://github.com/cncf/devstats/blob/master/INSTALL_UBUNTU16.md)
- [Linux Ubuntu 17](https://github.com/cncf/devstats/blob/master/INSTALL_UBUNTU17.md)
- [FreeBSD 11 (work in progress)](https://github.com/cncf/devstats/blob/master/INSTALL_FREEBSD.md)

# To drop & recreate InfluxDB:
- `IDB_HOST="localhost" IDB_PASS='idb_password' ./grafana/influxdb_recreate.sh`
- `GHA2DB_PROJECT=kubernetes GHA2DB_RESETIDB=1 PG_PASS='pwd' IDB_HOST="localhost" IDB_PASS='pwd' ./gha2db_sync`

Or automatically: drop & create Influx DB, update Postgres DB since the last run, full populate InfluxDB, start syncer every 30 minutes:
- `IDB_HOST="localhost" IDB_PASS=pwd PG_PASS=pwd ./kubernetes/reinit_all.sh`

# Alternate solution with Docker:

Note that this is an old solution that worked, but wasn't tested recently.

- Start Grafana using `GRAFANA_PASS='password' grafana/grafana_start.sh` to install Grafana & InfluxDB as docker containers (this requires Docker).
- Start InfluxDB using `IDB_HOST="localhost" IDB_PASS='password' IDB_PASS_RO='password' ./grafana/influxdb_setup.sh gha`, this requires Docker & previous command succesfully executed.
- To cleanup Docker Grafana image and start from scratch use `./grafana/docker_cleanup.sh`. This will not delete your grafana config because it is stored in local volume `/var/lib/grafana`.

# Manually feeding InfluxDB & Grafana:

Feed InfluxDB using:
- `PG_PASS='psql_pwd' IDB_HOST="localhost" IDB_PASS='influxdb_pwd' ./db2influx sig_metions_data metrics/kubernetes/sig_mentions.sql '2017-08-14' '2017-08-21' d`
- The first parameter is used as exact series name when metrics query returns single row with single column value.
- First parameter is used as function name when metrics query return mutiple rows, each with >= 2 columns. This function receives data row and the period name and should return series name and value(s).
- The second parameter is a metrics SQL file, it should contain time conditions defined as `'{{from}}'` and `'{{to}}'`.
- Next two parameters are date ranges.
- The last parameter can be h, d, w, m, q, y (hour, day, week, month, quarter, year).
- This tool uses environmental variables starting with `IDB_`, please see `context.go`, `idb_conn.go` and `cmd/db2influx/db2influx.go` for details.
- `IDB_` variables are exactly the same as `PG_` to set host, database, user name, password.
- There is also `z2influx` tool. It is used to fill given series with zeros. Typical usage: `./z2influx 'series1,series2' 2017-01-01 2018-01-01 w` - will fill all weeks from 2017 with zeros for series1 and series2.
- `annotations` tool adds variuos data annotations that can be used in Grafana charts. It uses GitHub API to fetch tags from project main repository defined in `projects.yaml`, it only includes tags matching annotation regexp also defined in `projects.yaml`.
- `idb_tags` tool used to add InfluxDB tags on some specified series. Those tags are used to populate Grafana template drop-down values and names. This is used to auto-populate Repository groups drop down, so when somebody adds new repository group - it will automatically appear in the drop-down.
- `idb_tags` uses [idb_tags.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/idb_tags.yaml) file to configure InfluxDB tags generation.
- `idb_backup` is used to backup/restore InfluxDB. Full renenerate of InfluxDB takes about 12 minutes. To avoid downtime when we need to rebuild InfluxDB - we can generate new InfluxDB on `test` database and then if succeeded, restore it on `gha`. Downtime will be about 2 minutes.
- You can use all defined environments variables, but add `_SRC` suffic for source database and `_DST` suffix for destination database.

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
If commit message contains `[no deploy]` then `webhook` is not performing any action on given branch.
If commit message contains `[ci skip]` then Travis CI skips build, so no webhook is called at all.
If commit message contains `[deploy]` then `webhook` attempts full deploy using `./devel/deploy_all.sh` script. It requires setting more environment variables for `webhook` command in the cron.

Details [here](https://github.com/cncf/devstats/blob/master/metrics/CONTINUOUS_DEPLOYMENT.md).

# Benchmarks
Benchmarks were executed on historical Ruby version and current Go version.

Please see [Historical benchmarks](https://github.com/cncf/devstats/blob/master/BENCHMARK.md)

# Testing

Please see [Tests](https://github.com/cncf/devstats/blob/master/TESTING.md)

### [DEVELOPMENT](https://github.com/cncf/devstats/blob/master/DEVELOPMENT.md)
# Developing locally

- Clone the repo.
- Checkout `production` branch (this is always a final working state on production machines`.
- Create branch from there.
- Follow install instructions for your platform.
- You don't need to have certbot SSL's, Apache proxy (it is only used to provide SSL and proxy to http Grafanas).
- You don't need domain names, you can install locally and just test using "http://127.0.0.1:3001" etc.

-  **annotations tool is not using GitHub API anymore, it uses `git_tags.sh` script instead.**, so this is historical (but there will be a new tool to get data from GHAPI so leaving this info here):
- You need to have GitHub OAuth token, either put this token in `/etc/github/oauth` file or specify token value via GHA2DB_GITHUB_OAUTH=deadbeef654...10a0 (here your token value).
- If you really don't want to use GitHub OAuth2 token, specify GHA2DB_GITHUB_OAUTH=- - this will force tokenless operation (via public API), it is a lot more rate limited (60 API points/h) than OAuth2 which gives 5000 API points/h.
### [TESTING](https://github.com/cncf/devstats/blob/master/TESTING.md)
# Testing
1. To execute tests that don't require database, just run `make test`, do not set any environment variables for them, one of tests is to check default environment!
2. For tests that require database you will have to set environment variables to enable DB connection, to do it:
- See [USAGE](https://github.com/cncf/devstats/blob/master/USAGE.md) for variables starting with `PG_` and `IDB_`.
- ALWAYS set `PG_DB` & `IFB_DB` - default values are "gha" for both database. They cannot be used as test databases, `make dbtest` will refuse to run when Postgres and/or Influx DB is not set (or set to "gha").
- Test cases are defined in `tests.yaml` file.
- Run tests like this: `PG_PASS=... IDB_PASS=.. GHA2DB_PROJECT=kubernetes IDB_HOST="localhost" IDB_DB=dbtest PG_DB=dbtest make dbtest`.
- Or use script shortcut: `PG_PASS=... IDB_PASS=... GHA2DB_PROJECT=kubernetes IDB_HOST="localhost" ./dbtest.sh`.
- To test only selected SQL metric(s): `PG_PASS=... GHA2DB_PROJECT=kubernetes PG_DB=dbtest TEST_METRICS='new_contributors,episodic_contributors' go test metrics_test.go`.
- To test single file that requires database: `PG_PASS=... IDB_PASS=... GHA2DB_PROJECT=kubernetes IDB_HOST="localhost" go test file_name.go`.
3. To check all sources using multiple go tools (like fmt, lint, imports, vet, goconst, usedexports), run `make check`.
4. To check Travis CI payloads use `PG_PASS=pwd IDB_PASS=pwd IDB_HOST=localhost IDB_PASS_SRC=pwd IGET=1 GET=1 ./webhook.sh` and then `./test_webhook.sh`.
5. Continuous deployment instructions are [here](https://github.com/cncf/devstats/blob/master/CONTINUOUS_DEPLOYMENT.md).
### [PULL_REQUEST_TEMPLATE](https://github.com/cncf/devstats/blob/master/PULL_REQUEST_TEMPLATE.md)
Please make sure that you follow instructions from [CONTRIBUTING](https://github.com/cncf/devstats/blob/master/CONTRIBUTING.md)

Specially:
- Check if all tests pass, see [TESTING](https://github.com/cncf/devstats/blob/master/TESTING.md) for deatils.
- Make sure you've added test coverage for new features/metrics.
- Make sure you have updated documentation.
- If you added a new metric, please make sure you have been following instructions about [adding new metric](https://github.com/cncf/devstats/blob/master/METRICS.md).
### [MULTIPROJECT](https://github.com/cncf/devstats/blob/master/MULTIPROJECT.md)
# Multiple Grafanas

You can run multiple Grafana instances using grafana/*/grafana_start.sh
You need to install Grafana and then create separate directories for all projects:
- `cp -R /usr/share/grafana /usr/share/grafana.projectname`.
- `cp -R /var/lib/grafana /var/lib/grafana.projectname`.
- `cp -R /etc/grafana /etc/grafana.projectname`.

# Configuration for running multiple projects on single host using Docker

- You need to install docker (see instruction for your Linux distro). This example uses `prometheus`, you can do the same for other projects by changing `prometheus` to other project (like `opentracing` for example).
- Docker instructions [here](https://github.com/cncf/devstats/blob/master/DOCKER.md).
- Start Grafana in a docker containser via `GRAFANA_PASS=... ./grafana/prometheus/docker_grafana_first_run.sh` (this is for first start when there are no `/etc/grafana.prometheus` and `/usr/share/grafana.prometheus` `directories yet).
- There are also `docker_grafana_run.sh`, `docker_grafana_start.sh`, `docker_grafana_stop.sh`, `docker_grafana_restart.sh`, `docker_grafana_shell.sh` scripts in `grafana/prometheus/`.
- Now you need to copy grafana config from the container to the host, do:
- Run `docker ps`, new grafana instance has some rangom name, for example output can be like this:
```
docker ps
CONTAINER ID        IMAGE                    COMMAND             CREATED             STATUS              PORTS                    NAMES
62e71b9d33d6        grafana/grafana:master   "/run.sh"           6 seconds ago       Up 5 seconds        0.0.0.0:3002->3000/tcp   quirky_chandrasekhar
b415070c6aa8        grafana/grafana:master   "/run.sh"           19 minutes ago      Up 4 minutes        0.0.0.0:3001->3000/tcp   prometheus_grafana
```
- In this case new container is named `quirky_chandrasekhar` and has container id `62e71b9d33d6`
- Login to the container via `docker exec -t -i 62e71b9d33d6 /bin/bash`.
- Inside the container: `cp -Rv /etc/grafana/ /var/lib/grafana/etc.grafana.prometheus`.
- Inside the container: `cp -Rv /usr/share/grafana /var/lib/grafana/share.grafana.prometheus`.
- Then exit the container `exit`.
- Then in the host: `mv /var/lib/grafana.prometheus/etc.grafana.prometheus/ /etc/grafana.prometheus`.
- Then in the host: `mv /var/lib/grafana.prometheus/share.grafana.prometheus/ /usr/share/grafana.prometheus`.
- Now you have container's config files in host `/var/lib/grafana.prometheus`, `/etc/grafana.prometheus` and `/var/lib/grafana.prometheus`.
- Stop temporary instance via `docker stop 62e71b9d33d6`.
- Start instance that uses freshly copied `/etc/grafana.prometheus` and `/usr/share/grafana.prometheus`: `./grafana/prometheus/docker_grafana_run.sh` and then `./grafana/prometheus/docker_grafana_start.sh`.
- Configure Grafana using `http://{{your_domain}}:3001` as described in [GRAFANA.md](https://github.com/cncf/devstats/blob/master/GRAFANA.md), note changes specific to docker listed below:
- InfluxDB name should point to 2nd, 3rd ... project Influx database, for example "prometheus".
- You won't be able to access InfluxDB running on localhost, you need to get host's virtual address from within docker container:
- `./grafana/prometheus/docker_grafana_shell.sh` and execute: `ip route | awk '/default/ { print $3 }'` to get container's gateway address (our host), for example `172.17.0.1`.
- This is also saved as `grafana/get_gateway_ip.sh`.
- Use http://{{gateway_ip}}:8086 as InfluxDB url.
- To edit `grafana.ini` config file (to allow anonymous access), you need to edit `/etc/grafana.prometheus/grafana.ini`.
- Instead of restarting the service via `service grafana-server restart` you need to restart docker conatiner via: `./grafana/prometheus/docker_grafana_restart.sh`.
- All standard Grafana folders are mapped into grafana.prometheus equivalents accessible on host to configure grafana inside docker container.
- Evereywhere when grafana server restart is needed, you should restart docker container instead.
- You should set instance name and all 3 cookie names (different for all dockerized grafanas): `vi /etc/grafana.{{project}}/grafana.ini`:
```
instance_name = {{project}}.cncftest.io
cookie_name = {{project}}_grafana_sess
cookie_username = {{project}}_grafana_user_test
cookie_remember_name = {{project}}_grafana_remember_test
```
- Remember to set those values differently on prod and test servers.

# Grafana sessions in Postgres

To enable storing Grafana session in Postgres database do (setting cookie names is not enough):
- `sudo -u postgres psql`
- `create database projectname_grafana_sessions;`
- `grant all privileges on database "projectname_grafana_sessions" to gha_admin;`
- `\q'
- You need to do the for all projects. Replace projectname with the current project.
- `sudo -u postgres psql projectname_grafana_sessions`
```
create table session(
  key char(16) not null,
  data bytea,
  expiry integer not null,
  primary key(key)
);
```
- `grant all privileges on table "session" to gha_admin;`
- This table and grant permission is also saved as `util_sql/grafana_session_table.sql`, so you can use: `sudo -u postgres psql projectname_grafana_sessions < util_sql/grafana_session_table.sql`.
- You need to do the for all projects. Replace projectname with current project.
- Your password should NOT contain # or ;, because Grafana is unable to escape it correctly.
- To change password do: `sudo -u postgres psql` and then `ALTER ROLE gha_admin WITH PASSWORD 'new_pwd';`.
```
provider = postgres
provider_config = user=gha_admin host=127.0.0.1 port=5432 dbname=projectname_grafana_sessions sslmode=disable password=...
```
- If you are adding sessions to dockerized Grafana instance you need to set hostname `172.17.0.1`.
- This is sometimes tricky to see why connection to Postgres fail. To be able to debug it do:
- `source /etc/default/grafana-server`
- `cd /usr/share/grafana`
- `/usr/sbin/grafana-server --config=${CONF_FILE} --pidfile=${PID_FILE_DIR}/grafana-server.pid cfg:default.paths.logs=${LOG_DIR} cfg:default.paths.data=${DATA_DIR} cfg:default.paths.plugins=${PLUGINS_DIR}`
- To see error logs of dockerized Grafana do:
- `docker logs projectname_grafana`
- Something like this: `panic: pq: no pg_hba.conf entry for host "172.17.0.2", user "gha_admin", database "projectname_grafana_sessions"` mean that you need to add:
- Add `host all all 172.17.0.0/24 md5` to your `/etc/postgresql/X.Y/main/pg_hba.conf` to allow all dockerized Grafanas to acces Postgres (from 172.17.0.xyz) address.
- You also need to add: `listen_addresses = '*'` to `/etc/postgresql/X.Y/main/postgresql.conf`.
- You shaould also add: `max_connections = 200` to `/etc/postgresql/X.Y/main/postgresql.conf`. Default is 100.
- `service postgresql restart`
### [CONTINUOUS_DEPLOYMENT](https://github.com/cncf/devstats/blob/master/CONTINUOUS_DEPLOYMENT.md)
# Continuous deployment (CD) using Travis

- Every commit triggers Travis CI tests.
- Once travis finishes tests, it fires webhook as defined in [.travis.yml](https://github.com/cncf/devstats/blob/master/.travis.yml).
- By default it makes HTTP POST to the following addresses: https://cncftest.io:2982/hook and https://devstats.cncf.io:2982/hook
- There is a tool `cmd/webhook/webhook` that listens to those webhook events.
- By default we use https protocol. To do so we need Apache server to proxy https requests on 2982 port, into http requests to localhost:1982 (webhook tool only understands http).
- To configure Apache we use those config files [ports.conf](https://github.com/cncf/devstats/blob/master/apache/ports.conf) and [000-default-le-ssl.conf](https://github.com/cncf/devstats/blob/master/apache/sites-available/000-default-le-ssl.conf).
- You can change `webhook`'s port via `GHA2DB_WHPORT` environment variable (default is 1982), `webhook`'s root via `GHA2DB_WHROOT` (default is `hook`) and `webhook`'s host via `GHA2DB_WHHOST` (default is 127.0.0.1).
- Please see [Usage](https://github.com/cncf/devstats/blob/master/USAGE.md) for details.
- By default `webhook` tool verifies payloads to determine if they are original Travis CI payloads.
- To enable testing locally you can start tool via `GOPATH=/path GHA2DB_PROJECT_ROOT=/path/to/repo PG_PASS=... GHA2DB_SKIP_VERIFY_PAYLOAD=1 ./webhook` or use ready script `webhook.sh` and then use `./test_webhook.sh` script for testing.
- You need to set both `GOPATH` and `GHA2DB_PROJECT_ROOT` because cron job environment have no environment variables set at all, you also have to set `PG_PASS` (this is to allow `webhook` to log into database in addition to `/tmp/gha2db_*` files).
- Webook must be run via cron job (it can be called every 5 minutes because every next instance will either start or do nothing due to port being used by previous instance).
- See [crontab.entry](https://github.com/cncf/devstats/blob/master/crontab.entry) for details, you need to tweak it a little and install via `crontab -e`.
- You can set `GHA2DB_DEPLOY_BRANCHES`, default "master", comma separated list, uto set which branches should be deployed.
- You can set `GHA2DB_DEPLOY_STATUSES`, default "Passed,Fixed", comma separated list, to set which branches should be deployed.
- You can set `GHA2DB_DEPLOY_RESULTS`, default "0", comma separated list, to set which Travis CI results should be deployed.
- You can set `GHA2DB_DEPLOY_TYPES`, default "push", comma separated list, to set which event types should be deployed.
- You *MUST* set `GHA2DB_PROJECT_ROOT=/path/to/repo` for webhook tool, this is needed to decide where to run `make install` on successful build.
- You should list only production branch via `GHA2DB_DEPLOY_BRANCHES=production` for production server, and you can list any number of branches for test servers: devstats.cncf.io is a production server, while cncftest.io is a test server.
- If you changed `webhook` tool and deploy was successful - you need to kill old running instance via `killall webhook` then wait for cron to fire it again, to se if it works use `ps -aux | grep webhook`.
- If you add `[ci skip]` to the commit message, Travis CI build will be skipped, so `webhook` tool won't be called at all (this skips tests).
- If you add `[no deploy]` to the commit message, Travis CI build will run, but `webhook` tool will not deploy this build.
- If you add `[deploy]` to the commit message, `webhook` will attempt to run full deploy script `./devel/deploy_all.sh`:
  - This script will deploy all missing projects (it creates databases, grafanas, certificates, basical creates any missing project from scratch).
  - You can use `GHA2DB_SKIP_FULL_DEPLOY=1` to disable this, this is a good idea on the test server, where you usually add all stuff manually, and even if not - you can manually call `./devel/deploy_all.sh` to see results.
  - To make full deploy work, you may want to configure additional environment variables.
  - You need to set standard Influx DB access variables (they're not needed when full deplopy script is not called): `IDB_HOST` and `IDB_PASS`.
  - Use `IGET=1` to allow deploy script to fetch Influx database from the test server instead of generating it locally from scratch (this is 100x faster for 'All CNCF' project case - this project must be updated everytime new CNCF project is added, so **this** is the recommended way).
  - `IGET=1` requires setting `IDB_PASS_SRC` - password for the test machine Influx to copy series from.
  - Use `GET=1` to allow deploy script to fetch Postgres database from the test server instead of generating it locally (also orders of magnitude faster than generating locally).
  - This fetches datbase dump which is available via WWW, so no additional password variables are needed.
  - You can deploy from webhook on the test server, but it would have to generate all data from scratch, so it will take a very long time and will be harder to debug becaus eit runs from the cron job.
  - Finally take a look at the example [crontab](https://github.com/cncf/devstats/blob/master/crontab.entry) file, it has comments about what to put in the test environment and what in the production.
- To check `webhook` tool locally use `PG_PASS=pwd IDB_PASS=pwd IDB_HOST=localhost IDB_PASS_SRC=pwd IGET=1 GET=1 ./webhook.sh` and then `./test_webhook.sh` from another terminal.
### [APACHE](https://github.com/cncf/devstats/blob/master/APACHE.md)
# Apache installation

- Install apache: `apt-get install apache2`
- Create "web" directory: `mkdir /var/www/html/` (it will hold gha databases dumps and other static info on the main domain.)
- Copy either `apache/www/index_test.html` or `apache/www/index_prod.html` to `/var/www/html` and adjust this file if needed.
- Enable mod proxy and mod rewrite:
- `ln /etc/apache2/mods-available/proxy.load /etc/apache2/mods-enabled/`
- `ln /etc/apache2/mods-available/proxy.conf /etc/apache2/mods-enabled/`
- `ln /etc/apache2/mods-available/proxy_http.load /etc/apache2/mods-enabled/`
- `ln /etc/apache2/mods-available/rewrite.load /etc/apache2/mods-enabled/`
- You can enable SSL, to do so You need to follow SSL instruction in [SSL](https://github.com/cncf/devstats/blob/master/SSL.md) (that requires domain name).
- `service apache2 restart`
### [INSTALL_MAC](https://github.com/cncf/devstats/blob/master/INSTALL_MAC.md)
# devstats installation on Mac

Prerequisites:
- macOS >= 10.12.
- [golang](https://golang.org), this tutorial uses Go 1.9
- [brew](https://brew.sh)

1. Configure Go:
    - Add those lines to `~/.bash_profile`:
    ```
    GOPATH=$HOME/dev/go; export GOPATH
    PATH=$PATH:$GOPATH/bin; export PATH
    ```
    - Logout and login again.
    - [golint](https://github.com/golang/lint): `go get -u github.com/golang/lint/golint`
    - [goimports](https://godoc.org/golang.org/x/tools/cmd/goimports): `go get golang.org/x/tools/cmd/goimports`
    - [goconst](https://github.com/jgautheron/goconst): `go get github.com/jgautheron/goconst/cmd/goconst`
    - [usedexports](https://github.com/jgautheron/usedexports): `go get github.com/jgautheron/usedexports`
    - [errcheck](https://github.com/kisielk/errcheck): `go get github.com/kisielk/errcheck`
    - Go InfluxDB client: install with: `go get github.com/influxdata/influxdb/client/v2`
    - Go Postgres client: install with: `go get github.com/lib/pq`
    - Go unicode text transform tools: install with: `go get golang.org/x/text/transform` and `go get golang.org/x/text/unicode/norm`
    - Go YAML parser library: install with: `go get gopkg.in/yaml.v2`
    - Go GitHub API client: `go get github.com/google/go-github/github`
    - Go OAuth2 client: `go get golang.org/x/oauth2`
    - Wget: install with: `brew install wget`

2. Go to $GOPATH/src/ and clone devstats there:
    - `git clone https://github.com/cncf/devstats.git`

3. If you want to make changes and PRs, please clone `devstats` from GitHub UI, and the clone your forked version instead, like this:
    - `git clone https://github.com/your_github_username/devstats.git`

4. Go to devstats directory, so you are in `~/dev/go/src/devstats` directory and compile binaries:
    - `make`

5. If compiled sucessfully then execute test coverage that doesn't need databases:
    - `make test`
    - Tests should pass.

6. Install binaries & metrics:
    - `sudo mkdir /etc/gha2db`
    - `sudo chmod 777 /etc/gha2db`
    - `sudo make install`

7. Install Postgres database ([link](https://gist.github.com/sgnl/609557ebacd3378f3b72)):
    - `brew doctor`
    - `brew update`
    - `brew install postgresql`
    - `brew services start postgresql`
    - `createdb gha`
    - `createdb devstats`
    - `psql gha`
    - Postgres only allows local connections by default so it is secure, we don't need to disable external connections:
    - Instructions to enable external connections (not recommended): `http://www.thegeekstuff.com/2014/02/enable-remote-postgresql-connection/?utm_source=tuicool`

8. Inside psql client shell:
    - `create user gha_admin with password 'your_password_here';`
    - `grant all privileges on database "gha" to gha_admin;`
    - `grant all privileges on database "devstats" to gha_admin;`
    - `alter user gha_admin createdb;`
    - Leave the shell and create logs table for devstats: `sudo -u postgres psql devstats < util_sql/devstats_log_table.sql`.

9. Leave `psql` shell, and get newest Kubernetes database dump:
    - `wget https://devstats.cncf.io/gha.dump`.
    - `sudo -u postgres pg_restore -d gha gha.dump` (restore DB dump)
    - Create `ro_user` via `PG_PASS=... ./devel/create_ro_user.sh`

10. Install InfluxDB time-series database ([link](https://docs.influxdata.com/influxdb/v0.9/introduction/installation/)):
    - `brew update`
    - `brew install influxdb`
    - `ln -sfv /usr/local/opt/influxdb/*.plist ~/Library/LaunchAgents`
    - `launchctl load ~/Library/LaunchAgents/homebrew.mxcl.influxdb.plist`
    - Create InfluxDB user, database: `IDB_HOST="localhost" IDB_PASS='your_password_here' IDB_PASS_RO='ro_user_password' ./grafana/influxdb_setup.sh gha`
    - InfluxDB has authentication disabled by default.
    - Edit config file and change section `[http]`: `auth-enabled = true`, `max-body-size = 0`, `[subscriber]`: `http-timeout = "300s"`, `write-concurrency = 96`, `[coordinator]`: `write-timeout = "60s"`.
    - If you want to disable external InfluxDB access (for any external IP, only localhost) follow those instructions [SECURE_INFLUXDB.md](https://github.com/cncf/devstats/blob/master/SECURE_INFLUXDB.md).
    - `sudo service influxdb restart`

11. Databases installed, you need to test if all works fine, use database test coverage:
    - `GHA2DB_PROJECT=kubernetes IDB_HOST="localhost" IDB_DB=dbtest IDB_PASS=your_influx_pwd PG_DB=dbtest PG_PASS=your_postgres_pwd make dbtest`
    - Tests should pass.

12. We have both databases running and Go tools installed, let's try to sync database dump from `k8s.devstats.cncf.io` manually:
    - We need to prefix call with GHA2DB_LOCAL to enable using tools from "./" directory
    - You need to have GitHub OAuth token, either put this token in `/etc/github/aoauth` file or specify token value via GHA2DB_GITHUB_OAUTH=deadbeef654...10a0 (here you token value)
    - If you really don't want to use GitHub OAuth2 token, specify `GHA2DB_GITHUB_OAUTH=-` - this will force tokenless operation (via public API), it is a lot more rate limited than OAuth2 which gives 5000 API points/h
    - To import data for the first time (Influx database is empty and postgres database is at the state when Kubernetes SQL dump was made on [k8s.devstats.cncf.io](https://k8s.devstats.cncf.io)):
    - `IDB_HOST="localhost" IDB_PASS=pwd PG_PASS=pwd ./kubernetes/reinit_all.sh`
    - This can take a while (depending how old is psql dump `gha.sql.xz` on [k8s.devstats.cncf.io](https://k8s.devstats.cncf.io). It is generated daily at 3:00 AM UTC.
    - Command should be successfull.

13. We need to setup cron job that will call sync every hour (10 minutes after 1:00, 2:00, ...)
    - You need to open `crontab.entry` file, it looks like this for single project setup (this is obsolete, please use `devstats` mode instead):
    ```
    8 * * * * PATH=$PATH:/path/to/your/GOPATH/bin GHA2DB_CMDDEBUG=1 GHA2DB_PROJECT=kubernetes IDB_HOST="localhost" IDB_PASS='...' PG_PASS='...' gha2db_sync 2>> /tmp/gha2db_sync.err 1>> /tmp/gha2db_sync.log
    30 3 * * * PATH=$PATH:/path/to/your/GOPATH/bin cron_db_backup.sh gha 2>> /tmp/gha2db_backup.err 1>> /tmp/gha2db_backup.log
    */5 * * * * PATH=$PATH:/path/to/your/GOPATH/bin GOPATH=/your/gopath GHA2DB_CMDDEBUG=1 GHA2DB_PROJECT_ROOT=/path/to/repo PG_PASS="..." GHA2DB_SKIP_FULL_DEPLOY=1 webhook 2>> /tmp/gha2db_webhook.err 1>> /tmp/gha2db_webhook.log
    ```
    - For multiple projects you can use `devstats` instead of `gha2db_sync` and `cron/cron_db_backup_all.sh` instead of `cron/cron_db_backup.sh`.
    ```
    7 * * * * PATH=$PATH:/path/to/GOPATH/bin IDB_HOST="localhost" IDB_PASS="..." PG_PASS="..." devstats 2>> /tmp/gha2db_sync.err 1>> /tmp/gha2db_sync.log
    30 3 * * * PATH=$PATH:/path/to/GOPATH/bin cron_db_backup_all.sh 2>> /tmp/gha2db_backup.err 1>> /tmp/gha2db_backup.log
    */5 * * * * PATH=$PATH:/path/to/GOPATH/bin GOPATH=/go/path GHA2DB_CMDDEBUG=1 GHA2DB_PROJECT_ROOT=/path/to/repo GHA2DB_DEPLOY_BRANCHES="production,master" PG_PASS=... GHA2DB_SKIP_FULL_DEPLOY=1 webhook 2>> /tmp/gha2db_webhook.err 1>> /tmp/gha2db_webhook.log
    ```
    - First crontab entry is for automatic GHA sync.
    - Second crontab entry is for automatic daily backup of GHA database.
    - Third crontab entry is for Continuous Deployment - this a Travis Web Hook listener server, it deploys project when specific conditions are met, details [here](https://github.com/cncf/devstats/blob/master/CONTINUOUS_DEPLOYMENT.md).
    - You need to change "..." PG_PASS, IDB_PASS, IDB_HOST to the real postgres password value and copy this line.
    - You need to change "/path/to/your/GOPATH/bin" to the value of "$GOPATH/bin", you cannot use $GOPATH in crontab directly.
    - Run `crontab -e` and put this line at the end of file and save.
    - Cron job will update Postgres and InfluxDB databases at 0:10, 1:10, ... 23:10 every day.
    - It outputs logs to `/tmp/gha2db_sync.out` and `/tmp/gha2db_sync.err` and also to gha Postgres database: into table `gha_logs`.
    - Check database values and logs about 15 minutes after full hours, like 14:15:
    - Check max event created date: `select max(created_at) from gha_events` and logs `select * from gha_logs order by dt desc limit 20`.

14. Install [Grafana](http://docs.grafana.org/installation/mac/) or use Docker to enable multiple Grafana instances, see [MULTIPROJECT.md](https://github.com/cncf/devstats/blob/master/MULTIPROJECT.md).
    - Docker on Mac isn't recommended.
    - `brew update`
    - `brew install grafana`
    - `brew services start grafana`
    - Configure Grafana, as described [here](https://github.com/cncf/devstats/blob/master/GRAFANA.md).
    - `brew services restart grafana`
    - Go to Grafana UI (localhost:3000), choose sign out, and then access localhost:3000 again. You should be able to view dashboards as a guest. To login again use http://localhost:3000/login.
    - Install Apache as described [here](https://github.com/cncf/devstats/blob/master/APACHE.md).
    - You can also enable SSL, to do so you need to follow SSL instruction in [SSL](https://github.com/cncf/devstats/blob/master/SSL.md) (that requires domain name).

15. To change all Grafana page titles (starting with "Grafana - ") and icons use this script:
    - `GRAFANA_DATA=/usr/share/grafana/ ./grafana/{{project}}/change_title_and_icons.sh`.
    - `GRAFANA_DATA` can also be `/usr/share/grafana.prometheus/` or `/usr/share/grafana.opentracing` for example, see [MULTIPROJECT.md](https://github.com/cncf/devstats/blob/master/MULTIPROJECT.md).
    - Replace `GRAFANA_DATA` with you Grafana data directory.
    - `brew services restart grafana`
    - In some cases browser and/or Grafana cache old settings in this case temporarily move Grafana's `settings.js` file:
    - `mv /usr/share/grafana/public/app/core/settings.js /usr/share/grafana/public/app/core/settings.js.old`, restart grafana server and restore file.

16. To enable Continuous deployment using Travis, please follow instructions [here](https://github.com/cncf/devstats/blob/master/CONTINUOUS_DEPLOYMENT.md).

17. You can create new metrics (as SQL files and YAML definitions) and dashboards in Grafana (export as JSON).
18. PRs and suggestions are welcome, please create PRs and Issues on the [GitHub](https://github.com/cncf/devstats).

# More details
- [Local Development](https://github.com/cncf/devstats/blob/master/DEVELOPMENT.md).
- [README](https://github.com/cncf/devstats/blob/master/README.md)
- [USAGE](https://github.com/cncf/devstats/blob/master/USAGE.md)
### [EXPORT](https://github.com/cncf/devstats/blob/master/EXPORT.md)
# Exporting data

Every dashboard can be exported to CSV.
- Click dashboard title - dialog will appear.
- Click then menu icon on the bottom-left.
- Choose "Export to CSV".
- You can select "series as rows" or "series as columns" for chart dashboards.
- You can specify date format and choose exel dialect.

### [INSTALL_FREEBSD](https://github.com/cncf/devstats/blob/master/INSTALL_FREEBSD.md)
# DevStats installation on FreeBSD

Prerequisites:
- FreeBSD (tested on FreeBSD 11.1 amd64)
- [golang](https://golang.org), this tutorial uses Go 1.9
    - 'pkg install bash git go sudo wget'
    - 'chsh (change to /usr/local/bin/bash)'
    - 'mkdir ~/dev; mkdir ~/dev/go; cd ~/dev/go; mkdir pkg bin src'
1. Configure Go:
    - For example add to '~/.profile':
     ```
     GOPATH=$HOME/dev/go; export GOPATH
     PATH=$PATH:$GOPATH/bin; export PATH
     ```
    - Update your '~/.netrc':
    ```
    machine github.com
      login <user>
      password <password>
    ```
    - Logout and login again.
    - [golint](https://github.com/golang/lint): `go get -u github.com/golang/lint/golint`
    - [goimports](https://godoc.org/golang.org/x/tools/cmd/goimports): `go get golang.org/x/tools/cmd/goimports`
    - [goconst](https://github.com/jgautheron/goconst): `go get github.com/jgautheron/goconst/cmd/goconst`
    - [usedexports](https://github.com/jgautheron/usedexports): `go get github.com/jgautheron/usedexports`
    - [errcheck](https://github.com/kisielk/errcheck): `go get github.com/kisielk/errcheck`
    - Go InfluxDB client: install with: `go get github.com/influxdata/influxdb/client/v2`
    - Go Postgres client: install with: `go get github.com/lib/pq`
    - Go unicode text transform tools: install with: `go get golang.org/x/text/transform` and `go get golang.org/x/text/unicode/norm`
    - Go YAML parser library: install with: `go get gopkg.in/yaml.v2`
    - Go GitHub API client: `go get github.com/google/go-github/github`
    - Go OAuth2 client: `go get golang.org/x/oauth2`
2. Go to $GOPATH/src/ and clone devstats there:
    - `git clone https://github.com/cncf/devstats.git`, cd `devstats`
3. If you want to make changes and PRs, please clone `devstats` from GitHub UI, and clone your forked version instead, like this:
    - `git clone https://github.com/your_github_username/devstats.git`
6. Go to devstats directory, so you are in `~/dev/go/src/devstats` directory and compile binaries:
    - `make`
7. If compiled sucessfully then execute test coverage that doesn't need databases:
    - `make test`
    - Tests should pass.
8. Install binaries & metrics:
    - `sudo mkdir /etc/gha2db`
    - `sudo chmod 777 /etc/gha2db`
    - `sudo make install`
9. Install Postgres database ([link](https://gist.github.com/sgnl/609557ebacd3378f3b72)):
    - sudo pkg install postgresql96-server
    - Add 'postgresql_enable="YES"' to /etc/rc.conf
    - service postgresql initdb
    - service postgresql start
    - sudo -i -u postgres
    - psql
    - Postgres only allows local connections by default so it is secure, we don't need to disable external connections:
    - Config file is: `/usr/local/share/postgresql/pg_hba.conf`, instructions to enable external connections (not recommended): `http://www.thegeekstuff.com/2014/02/enable-remote-postgresql-connection/?utm_source=tuicool`
10. Inside psql client shell (sudo -u postgres psql):
    - `create database gha;`
    - `create database devstats;`
    - `create user gha_admin with password 'your_password_here';`
    - `grant all privileges on database "gha" to gha_admin;`
    - `grant all privileges on database "devstats" to gha_admin;`
    - `alter user gha_admin createdb;`
    - Leave the shell and create logs table for devstats: `sudo -u postgres psql devstats < util_sql/devstats_log_table.sql`.
11. Leave `psql` shell, and get newest Kubernetes database dump:
    - `wget https://devstats.cncf.io/gha.dump`.
    - `sudo -u postgres pg_restore -d gha gha.dump` (restore DB dump)
    - Create `ro_user` via `PG_PASS=... ./devel/create_ro_user.sh`
12. Install InfluxDB time-series database ([link](https://docs.influxdata.com/influxdb/v0.9/introduction/installation/)):
    - `sudo pkg install influxdb`
    - `sudo service influxd start`
    - Add 'influxd_enable="YES"' to /etc/rc.conf
    - Create InfluxDB user, database: `IDB_HOST="localhost" IDB_PASS='your_password_here' IDB_PASS_RO='ro_user_password' ./grafana/influxdb_setup.sh gha`
    - InfluxDB has authentication disabled by default.
    - Edit config file `vim /usr/local/etc/influxdb.conf` and change section `[http]`: `auth-enabled = true`, `max-body-size = 0`, `[subscriber]`: `http-timeout = "300s"`, `write-concurrency = 96`, `[coordinator]`: `write-timeout = "60s"`.
    - If you want to disable external InfluxDB access (for any external IP, only localhost) follow those instructions [SECURE_INFLUXDB.md](https://github.com/cncf/devstats/blob/master/SECURE_INFLUXDB.md).
    - `sudo service influxdb restart`
13. Databases installed, you need to test if all works fine, use database test coverage:
    - `GHA2DB_PROJECT=kubernetes IDB_DB=dbtest IDB_HOST="localhost" IDB_PASS=your_influx_pwd PG_DB=dbtest PG_PASS=your_postgres_pwd make dbtest`
    - Tests should pass.
14. We have both databases running and Go tools installed, let's try to sync database dump from k8s.devstats.cncf.io manually:
    - We need to prefix call with GHA2DB_LOCAL to enable using tools from "./" directory
    - To import data for the first time (Influx database is empty and postgres database is at the state when Kubernetes SQL dump was made on [k8s.devstats.cncf.io](https://k8s.devstats.cncf.io)):
    - You need to have GitHub OAuth token, either put this token in `/etc/github/oauth` file or specify token value via GHA2DB_GITHUB_OAUTH=deadbeef654...10a0 (here you token value)
    - If you really don't want to use GitHub OAuth2 token, specify `GHA2DB_GITHUB_OAUTH=-` - this will force tokenless operation (via public API), it is a lot more rate limited than OAuth2 which gives 5000 API points/h
    - `IDB_HOST="localhost" IDB_PASS=pwd PG_PASS=pwd ./kubernetes/reinit_all.sh`
    - This can take a while (depending how old is psql dump `gha.sql.xz` on [k8s.devstats.cncf.io](https://k8s.devstats.cncf.io). It is generated daily at 3:00 AM UTC.
    - Command should be successfull.
15. We need to setup cron job that will call sync every hour (10 minutes after 1:00, 2:00, ...)
    - You need to open `crontab.entry` file, it looks like this for single project setup (this is obsolete, please use `devstats` mode instead):
    ```
    8 * * * * PATH=$PATH:/path/to/your/GOPATH/bin GHA2DB_CMDDEBUG=1 GHA2DB_PROJECT=kubernetes IDB_HOST="localhost" IDB_PASS='...' PG_PASS='...' gha2db_sync 2>> /tmp/gha2db_sync.err 1>> /tmp/gha2db_sync.log
    20 3 * * * PATH=$PATH:/path/to/your/GOPATH/bin cron_db_backup.sh gha 2>> /tmp/gha2db_backup.err 1>> /tmp/gha2db_backup.log
    */5 * * * * PATH=$PATH:/path/to/your/GOPATH/bin GOPATH=/your/gopath GHA2DB_CMDDEBUG=1 GHA2DB_PROJECT_ROOT=/path/to/repo PG_PASS="..." GHA2DB_SKIP_FULL_DEPLOY=1 webhook 2>> /tmp/gha2db_webhook.err 1>> /tmp/gha2db_webhook.log
    ```
    - For multiple projects you can use `devstats` instead of `gha2db_sync` and `cron/cron_db_backup_all.sh` instead of `cron/cron_db_backup.sh`.
    ```
    7 * * * * PATH=$PATH:/path/to/GOPATH/bin IDB_HOST="localhost" IDB_PASS="..." PG_PASS="..." devstats 2>> /tmp/gha2db_sync.err 1>> /tmp/gha2db_sync.log
    30 3 * * * PATH=$PATH:/path/to/GOPATH/bin cron_db_backup_all.sh 2>> /tmp/gha2db_backup.err 1>> /tmp/gha2db_backup.log
    */5 * * * * PATH=$PATH:/path/to/GOPATH/bin GOPATH=/go/path GHA2DB_CMDDEBUG=1 GHA2DB_PROJECT_ROOT=/path/to/repo GHA2DB_DEPLOY_BRANCHES="production,master" PG_PASS=... GHA2DB_SKIP_FULL_DEPLOY=1 webhook 2>> /tmp/gha2db_webhook.err 1>> /tmp/gha2db_webhook.log
    ```
    - First crontab entry is for automatic GHA sync.
    - Second crontab entry is for automatic daily backup of GHA database.
    - Third crontab entry is for Continuous Deployment - this a Travis Web Hook listener server, it deploys project when specific conditions are met, details [here](https://github.com/cncf/devstats/blob/master/CONTINUOUS_DEPLOYMENT.md).
    - You need to change "..." PG_PASS, IDB_HOST and IDB_PASS to the real postgres password value and copy this line.
    - You need to change "/path/to/your/GOPATH/bin" to the value of "$GOPATH/bin", you cannot use $GOPATH in crontab directly.
    - Run `crontab -e` and put this line at the end of file and save.
    - Cron job will update Postgres and InfluxDB databases at 0:10, 1:10, ... 23:10 every day.
    - It outputs logs to `/tmp/gha2db_sync.out` and `/tmp/gha2db_sync.err` and also to gha Postgres database: into table `gha_logs`.
    - Check database values and logs about 15 minutes after full hours, like 14:15:
    - Check max event created date: `select max(created_at) from gha_events` and logs `select * from gha_logs order by dt desc limit 20`.
16. Install [Grafana](http://docs.grafana.org/installation/)
    - `sudo pkg install grafana4`
    - Add 'grafana_enable="YES"' to /etc/rc.conf
    - Configure Grafana, as described [here](https://github.com/cncf/devstats/blob/master/GRAFANA.md).
    - `service grafana-server restart`
    - Go to Grafana UI (localhost:3000), choose sign out, and then access localhost:3000 again. You should be able to view dashboards as a guest. To login again use http://localhost:3000/login.
    - Install Apache as described [here](https://github.com/cncf/devstats/blob/master/APACHE.md).
    - You can also enable SSL, to do so you need to follow SSL instruction in [SSL](https://github.com/cncf/devstats/blob/master/SSL.md) (that requires domain name).
17. To change all Grafana page titles (starting with "Grafana - ") and icons use this script:
    - `GRAFANA_DATA=/usr/share/grafana/ ./grafana/{{project}}/change_title_and_icons.sh`.
    - `GRAFANA_DATA` can also be `/usr/share/grafana.prometheus/` for example, see [MULTIPROJECT.md](https://github.com/cncf/devstats/blob/master/MULTIPROJECT.md).
    - Replace `GRAFANA_DATA` with your Grafana data directory.
    - `service grafana-server restart`
    - In some cases browser and/or Grafana cache old settings in this case temporarily move Grafana's `settings.js` file:
    - `mv /usr/share/grafana/public/app/core/settings.js /usr/share/grafana/public/app/core/settings.js.old`, restart grafana server and restore file.
    - On Safari you can use Develop -> Empty Caches followed by refresh page (Command+R).
18. To enable Continuous deployment using Travis, please follow instructions [here](https://github.com/cncf/devstats/blob/master/CONTINUOUS_DEPLOYMENT.md).
19. You can create new metrics (as SQL files and YAML definitions) and dashboards in Grafana (export as JSON).
20. PRs and suggestions are welcome, please create PRs and Issues on the [GitHub](https://github.com/cncf/devstats).

# More details
- [Local Development](https://github.com/cncf/devstats/blob/master/DEVELOPMENT.md).
- [README](https://github.com/cncf/devstats/blob/master/README.md)
- [USAGE](https://github.com/cncf/devstats/blob/master/USAGE.md)
### [README](https://github.com/cncf/devstats/blob/master/README.md)
[![Build Status](https://travis-ci.org/cncf/devstats.svg?branch=master)](https://travis-ci.org/cncf/devstats)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/1357/badge)](https://bestpractices.coreinfrastructure.org/projects/1357)

# GitHub archives and git Grafana visualization dashboards

Author: Łukasz Gryglicki <lgryglicki@cncf.io>

This is a toolset to visualize GitHub [archives](https://www.githubarchive.org/) using Grafana dashboards.

GHA2DB stands for **G**it**H**ub **A**rchives to **D**ash**B**oards.

# Goal

We want to create a toolset for visualizing various metrics for the Kubernetes community (and also for all CNCF projects).

Everything is open source so that it can be used by other CNCF and non-CNCF open source projects.

The only requirement is that project must be hosted on a public GitHub repository/repositories.

# Forking and installing locally

This toolset uses only Open Source tools: GitHub archives, git, Postgres databases, InfluxDB time-series databases and multiple Grafana instances.
It is written in Go, and can be forked and installed by anyone.

Contributions and PRs are welcome.
If you see a bug or want to add a new metric please create an [issue](https://github.com/cncf/devstats/issues) and/or [PR](https://github.com/cncf/devstats/pulls).

To work on this project locally please fork the original [repository](https://github.com/cncf/devstats), and:
- [Compiling and running on macOS](./INSTALL_MAC.md).
- [Compiling and running on Linux Ubuntu 16 LTS](./INSTALL_UBUNTU16.md).
- [Compiling and running on Linux Ubuntu 17](./INSTALL_UBUNTU17.md).
- [Compiling and running on FreeBSD](./INSTALL_FREEBSD.md).

Please see [Development](https://github.com/cncf/devstats/blob/master/DEVELOPMENT.md) for local development guide.

For more detailed description of all environment variables, tools, switches etc, please see [Usage](https://github.com/cncf/devstats/blob/master/USAGE.md).

# Metrics

We want to support all kind of metrics, including historical ones.
Please see [requested metrics](https://docs.google.com/document/d/1o5ncrY6lVX3qSNJGWtJXx2aAC2MEqSjnML4VJDrNpmE/edit?usp=sharing) to see what kind of metrics are needed.
Many of them cannot be computed based on the data sources currently used.

# Repository groups

There are some groups of repositories that are grouped together as a repository groups.
They are defined in [scripts/kubernetes/repo_groups.sql](https://github.com/cncf/devstats/blob/master/scripts/kubernetes/repo_groups.sql).

To setup default repository groups:
- `PG_PASS=pwd ./kubernetes/setup_repo_groups.sh`.

This is a part of `kubernetes/psql.sh` script and [kubernetes psql dump](https://devstats.cncf.io/gha.sql.xz) already has groups configured.

In an 'All' project (https://all.cncftest.io) repository groups are mapped to individual CNCF projects [scripts/all/repo_groups.sql](https://github.com/cncf/devstats/blob/master/scripts/all/repo_groups.sql):

# Company Affiliations

We also want to have per company statistics. To implement such metrics we need a mapping of developers and their employers.

There is a project that attempts to create such mapping [cncf/gitdm](https://github.com/cncf/gitdm).

DevStats has an import tool that fetches company affiliations from `cncf/gitdm` and allows to create per company metrics/statistics.

If you see errors in the company affiliations, please open a pull request on [cncf/gitdm](https://github.com/cncf/gitdm) and the updates will be reflected on [https://k8s.devstats.cncf.io](https://k8s.devstats.cncf.io) a couple days after the PR has been accepted. Note that gitdm supports mapping based on dates, to account for developers moving between companies.

# Architecture

For architecture details please see [architecture](https://github.com/cncf/devstats/blob/master/ARCHITECTURE.md) file.

Detailed usage is [here](https://github.com/cncf/devstats/blob/master/USAGE.md)

# Adding new metrics

Please see [metrics](https://github.com/cncf/devstats/blob/master/METRICS.md) to see how to add new metrics.

# Adding new projects

To add new project follow [adding new project](https://github.com/cncf/devstats/blob/master/ADDING_NEW_PROJECT.md) instructions.

# Grafana dashboards

Please see [dashboards](https://github.com/cncf/devstats/blob/master/DASHBOARDS.md) to see list of already defined Grafana dashboards.

# Exporting data

Please see [exporting](https://github.com/cncf/devstats/blob/master/EXPORT.md).

# Detailed Usage instructions

- [USAGE](https://github.com/cncf/devstats/blob/master/USAGE.md)

# Servers

The servers to run `devstats` are generously provided by [Packet](https://www.packet.net/) bare metal hosting as part of CNCF's [Community Infrastructure Lab](https://github.com/cncf/cluster).

# One line run all projects

- Use `GHA2DB_PROJECTS_OVERRIDE="+cncf,+all" IDB_HOST="localhost" IDB_PASS=pwd PG_PASS=pwd devstats`.
- Or add this command using `crontab -e` to run every hour HH:10.

# Checking projects activity

- Use: `PG_PASS=... PG_DB=allprj ./devel/activity.sh '1 month,,' > all.txt`.
- Example results [here](https://cncftest.io/all.txt) - all CNCF project activity during January 2018, excluding bots.
### [METRICS](https://github.com/cncf/devstats/blob/master/METRICS.md)
# Adding new metrics

To add new metric (replace `{{project}}` with kubernetes, prometheus or any other project defined in `projects.yaml`):

1) Define parameterized SQL (with `{{from}}`, `{{to}}`  and `{{n}}` params) that returns this metric data. For histogram metrics define `{{periodi:alias.date_column}}` instead.
- {{n}} is only used in aggregate periods mode and it will get value from `Number of periods` drop-down. For example for 7 days MA (moving average) it will be 7.
- Use {{period:alias.date_column}} for quick ranges based metrics, to test such metric use `PG_PASS=... ./runq ./metrics/project/filename.sql qr '1 week,,'`.
- Use (actor_col {{exclude_bots}}) to skip bot activity.
- This SQL will be automatically called on different periods by `gha2db_sync` and/or `devstats` tool.
2) Define this metric in [metrics/{{project}}/metrics.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml) (file used by `gha2db_sync` tool).
- You can define this metric in `devel/test_metric.yaml` first (and eventually in `devel/test_gaps.yaml`, `devel/test_tags.yaml`) and run `devel/test_metric_sync.sh`
- Then call `influx -username gha_admin -password ...` floowed by `use test`, `precision rfc3339`, `show series`, 'select * from series_name` to see the results.
- You need to define periods for calculations, for example m,q,y for "month, quarter and year", or h,d,w for "hour, day and week". You can use any combination of h,d,w,m,q,y. You can also use `annotations_ranges: true` for tabular tables with automatic quick ranges.
- You can define aggregate periods via `aggregate: n1,n2,n3,...`, if you don't define this, there will be one aggregation period = 1. Some aggregate combinations can be set to skip, for example you have `periods: m,q,y`, `aggregate: 1,3,7`, you want to skip >1 aggregate for y and 7 for q, then set: `skip: y3,y7,q3`.
- You need to define SQL file via `sql: filename`. It will use `metrics/{{project}}/filename.sql`.
- You need to define how to generate InfluxDB series name(s) for this metrics. There are 4 options here:
- Metric can return a single row with a single value (like for instance "All PRs merged" - in that case, you can define series name inside YAML file via `series_name_or_func: your_series_name`. If metrics use more than single period, You should add `add_period_to_name: true` which will add period name to your series name (it adds _w, _d, _q etc.)
- Metric can return a single row containing multiple columns, for example, "Time opened to merged". It returns lower percentile, median and higher percentile for the time from open to merge for PRs in a given period. You should use `series_name_or_func: single_row_multi_column` in such case, and SQL should return single row, with the first column in format `series_name1,seriesn_name2,...,series_nameN` and then N value columns. The period name will be added to all N series automatically.
- Metric can return multiple rows, each containing column with series name and column with a value. Use `series_name_or_func: multi_row_single_column` in such case, for example "SIG mentions categories". Metric should return 0-N rows each one containing series name in format `prefix,series_name`, followed by value column. Series names would be in format `prefix_series_name_period`. The prefix is optional, you can use `,series_name` - it will create "series_name_period", `series_name` comes from metric so it will be normalized (like downcased, white space characters changed to underscores, UTF8 characters normalized or stripped etc.). Such series returns different row counts for different periods (for example some SIG were not mentioned in some periods). This creates data gaps.
- Metric can return multiple rows with multiple columns. You should use `series_name_or_func: multi_row_multi_column` in such case, for example, "Companies velocity", it returns multiple rows (companies) each row containing multiple company measurements (activities, authors, commits etc.). This requires special format of the first column: `prefix;series_name;measurement1,measurement2,...,measurementN`. `series_names` changes for each row, and will be normalized as if `multi_row_single_column`, the prefix is also optional as if `multi_row_single_column`. Then each row will create N series in format: `prefix_series_name_measurement1_period`, ... `prefix_series_name_measurementN_period` or if period is skipped: `series_name_measurementI_period`. Those metrics also create data gaps.
- For "histogram" metrics `histogram: true` we are putting data for last `{{period}}` using some string key instead of timestamp data. So for example simplest metric (single row, single column) means: multiple rows with hist "values", each value being "name,value" pair.
- Simplest type of histogram `series_name_or_func` is just a InfluxDB series name. Because we're calculating histogram for last `{{period}}` each time, given series is cleared and recalculated.
- Metric can return multiple rows with single column (which means 3 columns in histogram mode: `prefix,series_name` and then histogram value (2 columns: `name` and `value`), exactly the same as `series_name_or_func: multi_row_single_column`.
- If metrics need additiona string descriptions (like when we are returning number of hours as age, and want to have nice formatted string value like "1 day 12 hours") use `desc: time_diff_as_string`.
- Metric can return multiple values in a single series (for example for SIG mentions stacking, bot commands, company stats etc), use `multi_value: true` to mark series to return multi value in a single series (instead of creating multiple series with single values). Multi values are used for stacked charts with multi value drop down to select series.
- If you want to escape value names in multi-valued series use `escape_value_name: true` in `metrics.yaml`.
3) If metrics create data gaps (for example returns multiple rows with different counts depending on data range), you have to add automatic filling gaps in [metrics/{{project}}gaps.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/gaps.yaml) (file is used by `z2influx` tool):
- Please try to use Grafana's "null as zero" feature when stacking series instead. Gaps filling is only needed when using data from > 1 Influx series. If you need this, use [GAPS.md](https://github.com/cncf/devstats/blob/master/GAPS.md).
4) Add test coverage in [metrics_test.go](https://github.com/cncf/devstats/blob/master/metrics_test.go) and [tests.yaml](https://github.com/cncf/devstats/blob/master/tests.yaml).
5) You need to either regenerate all InfluxDB data, using `PG_PASS=... IDB_PASS=... ./reinit_all.sh` or use `PG_PASS=... IDB_PASS=... ./devel/add_single_metric,sh`. If you choose to use add single metric, you need to create 3 files: `test_gaps.yaml` (if empty copy from metrics/{{project}}empty.yaml), `test_metrics.yaml` and `test_tags.yaml`. Those YAML files should contain only new metric related data.
6) To test new metric on non-production InfluxDB "test", use: `GHA2DB_PROJECT={{project}} ./devel/test_metric_sync.sh` script. You can chekc field types via: `influx; use test; show field keys`.
7) Add Grafana dashboard or row that displays this metric.
8) Export new Grafana dashboard to JSON.
9) Create PR for the new metric.
10) Add metrics dashboard decription in this [file](https://github.com/cncf/devstats/blob/master/DASHBOARDS.md).
11) Add more detailed documentation in [dashboards documentation](https://github.com/cncf/devstats/blob/master/docs/dashboards/).

# Tags

You can define tags in [metrics/{{project}}/idb_tags.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/idb_tags.yaml)
### [CODE_OF_CONDUCT](https://github.com/cncf/devstats/blob/master/CODE_OF_CONDUCT.md)
# Contributor Covenant Code of Conduct

## Our Pledge

In the interest of fostering an open and welcoming environment, we as contributors and maintainers pledge to making participation in our project and our community a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, gender identity and expression, level of experience, nationality, personal appearance, race, religion, or sexual identity and orientation.

## Our Standards

Examples of behavior that contributes to creating a positive environment include:

* Using welcoming and inclusive language
* Being respectful of differing viewpoints and experiences
* Gracefully accepting constructive criticism
* Focusing on what is best for the community
* Showing empathy towards other community members

Examples of unacceptable behavior by participants include:

* The use of sexualized language or imagery and unwelcome sexual attention or advances
* Trolling, insulting/derogatory comments, and personal or political attacks
* Public or private harassment
* Publishing others' private information, such as a physical or electronic address, without explicit permission
* Other conduct which could reasonably be considered inappropriate in a professional setting

## Our Responsibilities

Project maintainers are responsible for clarifying the standards of acceptable behavior and are expected to take appropriate and fair corrective action in response to any instances of unacceptable behavior.

Project maintainers have the right and responsibility to remove, edit, or reject comments, commits, code, wiki edits, issues, and other contributions that are not aligned to this Code of Conduct, or to ban temporarily or permanently any contributor for other behaviors that they deem inappropriate, threatening, offensive, or harmful.

## Scope

This Code of Conduct applies both within project spaces and in public spaces when an individual is representing the project or its community. Examples of representing a project or community include using an official project e-mail address, posting via an official social media account, or acting as an appointed representative at an online or offline event. Representation of a project may be further defined and clarified by project maintainers.

## Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be reported by contacting the project team at lukaszgryglicki@o2.pl. The project team will review and investigate all complaints, and will respond in a way that it deems appropriate to the circumstances. The project team is obligated to maintain confidentiality with regard to the reporter of an incident. Further details of specific enforcement policies may be posted separately.

Project maintainers who do not follow or enforce the Code of Conduct in good faith may face temporary or permanent repercussions as determined by other members of the project's leadership.

## Attribution

This Code of Conduct is adapted from the [Contributor Covenant][homepage], version 1.4, available at [http://contributor-covenant.org/version/1/4][version]

[homepage]: http://contributor-covenant.org
[version]: http://contributor-covenant.org/version/1/4/
### [GAPS](https://github.com/cncf/devstats/blob/master/GAPS.md)
# Filling data gaps (outdated)

If metrics create data gaps (for example returns multiple rows with different counts depending on data range), you have to add automatic filling gaps in [metrics/{{project}}gaps.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/gaps.yaml) (file is used by `z2influx` tool):
- Please try to use Grafana's "null as zero" feature when stacking series instead. This gaps configuartion description is outdated.
- You need to define periods to fill gaps, they should be the same as in `metrics.yaml` definition.
- You need to define a series list to fill gaps on them. Use `series: ` to set them. It expects a list of series (YAML list).
- You need to define the same `aggregate` and `skip` values for gaps too.
- You should at least gap fill series visible on any Grafana dashboard, without doing so data display will be disturbed. If you only show subset of metrics series, you can gap fill only this subset.
- Each entry can be either a full series name, like `- my_series_d` or ...
- It can also be a series formula to create series list in this format: `"- =prefix;suffix;join_string;list1item1,list1item2,...;list2item1,list2item2,...;..."`
- Series formula allows writing a lot of series name in a shorter way. Say we have series in this form prefix_{x}_{y}_{z}_suffix and {x} can be a,b,c,d, {y} can be 1,2,3, z can be yes,no. Instead of listing all combinations prefix_a_1_yes_suffix, ..., prefix_d_3_no_suffix, which is 4 * 3 * 2 = 24 items, you can write series formula: `- =prefix;suffix;_;a,b,c,d;1,2,3;yes,no`. In this case you can see join character is _ `...;_;...`.
- If metrics uses string descriptions (like `desc: time_diff_as_string`), add `desc: true` in gaps file to clear descriptions too.
- If Metric returns multiple values in a single series and creates data gaps, then you have to list values to clear via `values: ` property, you can use series formula format to do so.
### [SECURE_INFLUXDB](https://github.com/cncf/devstats/blob/master/SECURE_INFLUXDB.md)
# Securing InfluxDB

- Edit config file `vim /etc/influxdb/influxdb.conf` and change section [http] and change:
- If you use native Grafana: `bind-address = "127.0.0.1:8086"`. Address 0.0.0.0:8086 allows connecting from any external IP, while 127.0.0.1 only allows local connections.
- If you use Dockerized Grafana: bind-address = "{docker_gateway_ip}:8086" (for example `172.17.0.1`), obtain docker gateway IP using `grafana/get_gateway_ip.sh` while connected to the docker container via: `./grafana/{project}/docker_grafana_shell.sh`.
- Note that if using docker gateway ip default connection to influxDB will no longer work, so you will have to use `IDB_HOST="http://172.17.0.1"` everywhere when connecting to InfluxDB.
### [SSL](https://github.com/cncf/devstats/blob/master/SSL.md)
# Enable SSL/https Grafana (Ubuntu 17 using certbot)

To install Let's encrypt via certbot:

- First you need to install certbot, this is for example for Apache on Ubuntu 17.04:
- `sudo apt-get update`
- `sudo apt-get install software-properties-common`
- `sudo add-apt-repository ppa:certbot/certbot`
- `sudo apt-get update`
- `sudo apt-get install python-certbot-apache`
- `sudo certbot --apache`
- To install certificate for multiple domains use: `sudo certbot --apache -d 'domain1,domain2,..,domainN'`
- Choose to redirect all HTTP trafic to HTTPS.
- Then you need to proxy Apache https/SSL on port 443 to http on port 3000 (this is where Grafana listens)
- Your Grafana lives in https://your-domain.xyz (and https is served by Apache proxy to Grafana https:443 -> http:3000)
- In multiple hostnames used on single IP/Apache server, then you will redirect to different ports depending on current host name
- See `apache/sites-available/000-default-le-ssl.conf` for details (cncftest.io and prometheus.cncftest.io configured there).
- Modified Apache config files are in [apache](https://github.com/cncf/devstats/blob/master/apache/), you need to check them and enable something similar on your machine.
- You can for instance put [database dump](https://devstats.cncf.io/gha.sql.xz) there (main domain is a static page, all projects live in subdomains).
- Files in `[apache](https://github.com/cncf/devstats/blob/master/apache/) should be copied to `/etc/apache2` (see comments starting with `LG:`) and then `service apache2 restart`
- You can configure multiple domains for a single server:
- `sudo certbot --apache -d 'cncftest.io,k8s.cncftest.io,prometheus.cncftest.io,opentracing.cncftest.io,fluentd.cncftest.io,linkerd.cncftest.io,grpc.cncftest.io,coredns.cncftest.io,cncf.cncftest.io'`
- Most up to date commands to request SSL cers are at the botom of [this](https://github.com/cncf/devstats/blob/master/ADDING_NEW_PROJECT.md) file.
### [DASHBOARDS](https://github.com/cncf/devstats/blob/master/DASHBOARDS.md)
# Grafana dashboards

This is a list of dashboards for Kubernetes project only:

Each dashboard is defined by its metrics SQL, saved Grafana JSON export and link to dashboard running on <https://k8s.devstats.cncf.io>  

Many dashboards use "Repository group" drop-down. Repository groups are defined manually to group similar repositories into single projects.
They are defined here: [repo_groups.sql](https://github.com/cncf/devstats/blob/master/scripts/kubernetes/repo_groups.sql)

1) Reviewers dashboard: [user documentation](https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/reviewers.md), [developer documentation](https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/reviewers_devel.md), [reviewers.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/reviewers.sql), [reviewers.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json), [view](https://k8s.devstats.cncf.io/dashboard/db/reviewers?orgId=1).
2) SIG mentions dashboard: [user documentation](https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions.md), [developer documentation](https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions_devel.md), [sig_mentions.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/sig_mentions.sql), [sig_mentions.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions.json), [view](https://k8s.devstats.cncf.io/dashboard/db/sig-mentions?orgId=1).
3) SIG mentions breakdown by categories dashboard: [user documentation](https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions_cats.md), [developer documentation](https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions_cats_devel.md), [sig_mentions_cats.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/sig_mentions_cats.sql), [sig_mentions_breakdown.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/sig_mentions_breakdown.sql), [sig_mentions_categories.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_categories.json), [view](https://k8s.devstats.cncf.io/dashboard/db/sig-mentions-categories?orgId=1).
4) SIG mentions using labels dashboard: [user documentation](https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions_labels.md), [developer documentation](https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions_labels_devel.md),  [labels_sig.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_sig.sql), [labels_kind.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_kind.sql), [labels_sig_kind.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_sig_kind.sql), [sig_mentions_using_labels.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_using_labels.json), [view](https://k8s.devstats.cncf.io/dashboard/db/sig-mentions-using-labels?orgId=1).
5) The Number of PRs merged per repository dashboard [prs_merged.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/prs_merged.sql), [prs_merged.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/prs_merged.json), [view](https://k8s.devstats.cncf.io/dashboard/db/prs-merged?orgId=1).
6) PRs from opened to merged, from 2014-06 dashboard [opened_to_merged.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/opened_to_merged.sql), [opened_to_merged.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/opened_to_merged.json), [view](https://k8s.devstats.cncf.io/dashboard/db/opened-to-merged?orgId=1).
7) PRs from opened to LGTMed, approved and merged dashboard [time_metrics.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/time_metrics.sql), [time_metrics.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/time_metrics.json), [view](https://k8s.devstats.cncf.io/dashboard/db/time-metrics?orgId=1).
8) PR Comments dashboard [pr_comments.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/pr_comments.sql), [pr_comments.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/pr_comments.json), [view](https://k8s.devstats.cncf.io/dashboard/db/pr-comments?orgId=1).
9) Companies velocity dashboard [company_activity.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/company_activity.sql), [companies_velocity.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/companies_velocity.json), [view](https://k8s.devstats.cncf.io/dashboard/db/companies-velocity?orgId=1).
10) Companies stats dashboard [company_activity.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/company_activity.sql), [companies_stats.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/companies_stats.json), [view](https://k8s.devstats.cncf.io/dashboard/db/companies-stats?orgId=1).
11) The Number of PRs merged per repository groups dashboard [prs_merged_groups.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/prs_merged_groups.sql), [prs_merged_repository_groups.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/prs_merged_repository_groups.json), [view](https://k8s.devstats.cncf.io/dashboard/db/prs-merged-repository-groups?orgId=1).
12) Reviewers histogram dashboard: [hist_reviewers.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/hist_reviewers.sql), [reviewers_histogram.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers_histogram.json), [view](https://k8s.devstats.cncf.io/dashboard/db/reviewers-histogram?orgId=1).
13) Repository comments dashboard: [repo_comments.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/repo_comments.sql), [repository_comments.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/repository_comments.json), [view](https://k8s.devstats.cncf.io/dashboard/db/repository-comments?orgId=1).
14) Repository unique commenters dashboard: [repo_commenters.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/repo_commenters.sql), [repository_commenters.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/repository_commenters.json), [view](https://k8s.devstats.cncf.io/dashboard/db/repository-commenters?orgId=1).
15) New PRs dashboard: [new_prs.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/new_prs.sql), [new_prs.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/new_prs.json), [view](https://k8s.devstats.cncf.io/dashboard/db/new-prs?orgId=1).
16) PRs unique authors dashboard: [prs_authors.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/prs_authors.sql), [prs_authors.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/prs_authors.json), [view](https://k8s.devstats.cncf.io/dashboard/db/prs-authors?orgId=1).
17) Opened PRs age/count dashboard: [prs_age.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/prs_age.sql), [prs_age.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/prs_age.json), [view](https://k8s.devstats.cncf.io/dashboard/db/prs-age?orgId=1).
18) Top commenters dashboard: [hist_commenters.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/hist_commenters.sql), [top_commenters.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/top_commenters.json), [view](https://k8s.devstats.cncf.io/dashboard/db/top-commenters?orgId=1).
19) Community stats dashboard: [watchers.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/watchers.sql), [community_stats.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/community_stats.json), [view](https://k8s.devstats.cncf.io/dashboard/db/community-stats?orgId=1).
20) First non-author activity dashboard: [first_non_author_activity.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/first_non_author_activity.sql), [first_non_author_activity.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/first_non_author_activity.json), [view](https://k8s.devstats.cncf.io/dashboard/db/first-non-author-activity?orgId=1).
21) Bot commands usage dashboard: [bot_commands.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/bot_commands.sql), [bot_commands.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/bot_commands.json), [view](https://k8s.devstats.cncf.io/dashboard/db/bot-commands?orgId=1).
22) Contributing companies dashboard: [num_stats.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/num_stats.sql), [contributing_companies.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/contributing_companies.json), [view](https://k8s.devstats.cncf.io/dashboard/db/contributing-companies?orgId=1).
23) Approvers dashboard: [approvers.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/approvers.sql), [approvers.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/approvers.json), [view](https://k8s.devstats.cncf.io/dashboard/db/approvers?orgId=1).
24) Approvers histogram dashboard: [hist_approvers.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/hist_approvers.sql), [approvers_histogram.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/approvers_histogram.json), [view](https://k8s.devstats.cncf.io/dashboard/db/approvers-histogram?orgId=1).
25) SIG issues dashboard: [labels_sig_kind.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_sig_kind.sql), [labels_sig_kind_closed.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_sig_kind_closed.sql), [sig_issues.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_issues.json), [view](https://k8s.devstats.cncf.io/dashboard/db/sig-issues?orgId=1).
26) Issues repository group dashboard: [issues_opened.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/issues_opened.sql), [issues_closed.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/issues_closed.sql), [issues_repository_groups.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/issues_repository_groups.json), [view](https://k8s.devstats.cncf.io/dashboard/db/issues-repository-group?orgId=1).
27) PRs approval dashboard: [prs_state.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/prs_state.sql), [prs_approval.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/prs_approval.json), [view](https://k8s.devstats.cncf.io/dashboard/db/prs-approval?orgId=1).
28) PRs approval stacked dashboard: [prs_state.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/prs_state.sql), [prs_approval_stacked.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/prs_approval_stacked.json), [view](https://k8s.devstats.cncf.io/dashboard/db/prs-approval-stacked?orgId=1).
29) PRs authors histogram dashboard: [hist_pr_authors.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/hist_pr_authors.sql), [prs_authors_histogram.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/prs_authors_histogram.json), [view](https://k8s.devstats.cncf.io/dashboard/db/prs-authors-histogram?orgId=1).
30) PRs authors companies histogram dashboard: [hist_pr_companies.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/hist_pr_companies.sql), [prs_authors_companies_histogram.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/prs_authors_companies_histogram.json), [view](https://k8s.devstats.cncf.io/dashboard/db/prs-authors-companies-histogram?orgId=1).
31) Blocked dashboard: [prs_blocked.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/prs_blocked.sql), [blocked_prs.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/blocked_prs.json), [view](https://k8s.devstats.cncf.io/dashboard/db/blocked-prs?orgId=1).
32) Need rebase PRs dashboard: [prs_rebase.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/prs_rebase.sql), [need_rebase_prs.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/need_rebase_prs.json), [view](https://k8s.devstats.cncf.io/dashboard/db/need-rebase-prs?orgId=1).
33) Issues age dashboard: [issues_age.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/issues_age.sql), [issues_age.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/issues_age.json), [view](https://k8s.devstats.cncf.io/dashboard/db/issues-age?orgId=1).
34) Suggested approvers dashboard [other_approver.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/other_approver.sql), [suggested_approvers.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/suggested_approvers.json), [view](https://k8s.devstats.cncf.io/dashboard/db/suggested-approvers?orgId=1).
35) Project statistics dashboard [project_stats.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/project_stats.sql), [project_statistics.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/project_statistics.json), [view](https://k8s.devstats.cncf.io/dashboard/db/project-statistics?orgId=1).
36) Companies summary dashboard [project_company_stats.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/project_company_stats.sql), [companies_summary.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/companies_summary.json), [view](https://k8s.devstats.cncf.io/dashboard/db/companies-summary?orgId=1).
37) Developers summary dashboard [project_developer_stats.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/project_developer_stats.sql), [developers_summary.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/developers_summary.json), [view](https://k8s.devstats.cncf.io/dashboard/db/developers-summary?orgId=1).
38) Activity repository groups dashboard [activity_repo_groups.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/activity_repo_groups.sql), [activity_repo_groups.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/activity_repo_groups.json), [view](https://k8s.devstats.cncf.io/d/000000079/activity-repository-groups?orgId=1).
39) Commits in repository groups dashboard [commits_repo_groups.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/commits_repo_groups.sql), [commits_repo_groups.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/activity_repo_groups.json), [view](https://k8s.devstats.cncf.io/d/UeP_tSqkz/commits-repository-groups?orgId=1).
40) PR workload dashboard [pr_workload.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/pr_workload.sql), [pr_workload.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/pr_workload.json), [view](https://k8s.devstats.cncf.io/d/hnphTo3kk/pr-workload?orgId=1).
41) PR workload table dashboard [pr_workload_table.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/pr_workload_table.sql), [pr_workload_table.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/pr_workload_table.json), [view](https://k8s.devstats.cncf.io/d/QQN85o3zk/pr-workload-table?orgId=1).
42) Open issues/PRs by milestone dashboard [open_issues_sigs_milestones.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/open_issues_sigs_milestones.sql), [open_prs_sigs_milestones.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/open_prs_sigs_milestones.sql), [open_issues_prs_by_milestone.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/open_issues_prs_by_milestone.json), [view](https://k8s.devstats.cncf.io/d/22/open-issues-prs-by-milestone?orgId=1).
43) User reviews dashboard [reviews_per_user.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/reviews_per_user.sql), [user_reviews.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/user_reviews.json), [view](https://k8s.devstats.cncf.io/d/46/user-reviews?orgId=1).

# Index dashboard showing all projects
1) All CNCF projects dashboard [user documentation](https://github.com/cncf/devstats/blob/master/docs/dashboards/dashboards.md), [developer documentation](https://github.com/cncf/devstats/blob/master/docs/dashboards/dashboards_devel.md), [dashboards.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json), [view](https://k8s.devstats.cncf.io/dashboard/db/dashboards?refresh=15m&orgId=1).

All of them works live on [k8s.devstats.cncf.io](https://k8s.devstats.cncf.io) with auto `devstats` tool running.

Dashboard definitions are read from YAML file:  [metrics/kubernetes/metrics.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml)

If dashboard needs an additional preprocessing (filling gaps with zeros), then it must be listed in this YAML file:  [metrics/kubernetes/gaps.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/gaps.yaml).
Please use Grafana's "null as zero" instead of using manuall filling gaps. This simplifies metrics a lot.

See [adding new metrics](https://github.com/cncf/devstats/blob/master/METRICS.md) for details.

Similar set of metrics is defined for Prometheus, OpenTracing, ..., Rook (All CNCF Projects):

- SQL metris in `metrics/prometheus/` directory, Influx templates/tags `metrics/prometheus/*tags*.sql` files. Prometheus dashboards: `grafana/dashboards/prometheus/` directory.
- SQL metris in `metrics/opentracing/` directory, Influx templates/tags `metrics/opentracing/*tags*.sql` files. OpenTracing dashboards: `grafana/dashboards/opentracing/` directory.
- And so on...

There is also an 'All' [Project](https://all.cncftest.io) on the test server that contains all CNCF projects data combined. Each CNCF projects is a repository group there.

# Adding new project

To add new project follow [adding new project](https://github.com/cncf/devstats/blob/master/ADDING_NEW_PROJECT.md) instructions.
### [GRAFANA](https://github.com/cncf/devstats/blob/master/GRAFANA.md)
# Grafana configuration

- Go to Grafana UI: `http://localhost:3000`
- Login as "admin"/"admin" (you can change passwords later).
- Choose add data source, then Add Influx DB with those settings:
- Name "gha" and type "InfluxDB", url default "http://localhost:8086"/"http://127.0.0.1:8086", access: "proxy", database "projname", user "ro_user", password "influx_pwd", min time interval "1h"
- Test & save datasource, then proceed to dashboards.
- Choose add data source, then add PostgreSQL with those settings:
- Name "psql", Type "PostgreSQL", host "127.0.0.1:5432", database "projname", user "ro_user" (this is the select-only user for psql), password "your-psql-password", ssl-mode "disabled".
- Make sure to run `./devel/ro_user_grants.sh projname` to add `ro_user's` select grants for all psql tables in projectname.
- If doing this for the first time also create `ro_user` via `devel/create_ro_user.sh`.
- Click Home, Import dashboard, Upload JSON file, choose dashboards saved as JSONs in `grafana/dashboards/{{project}}dashboard_name.json`, data source "InfluxDB" and save.
- All dashboards are here: [kubernetes](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/), [prometheus](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/), [opentracing](https://github.com/cncf/devstats/blob/master/grafana/dashboards/opentracing/).
- Do the same for all defined dashboards. Use specific project tag, for example `kubernetes`, `prometheus` or `opentracing`.
- Import main home for example [kubernetes dahsboard](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json).
- Set some dashboard(s) as "favorite" - star icon, you can choose home dashboard only from favorite ones.
- Choose Admin -> Preferences, name your organization (for example set it to `XYZ`), same with Admin -> profile.
- Set your home dashboard to just imported "Dashboards".
- You can also **try** to use current [grafana.db](https://devstats.cncf.io/grafana.k8s.db) to import everything at once, but be careful, because this is file is version specific.
- When finished, copy final settings file `grafana.db`: `cp /var/lib/grafana.proj/grafana.db /var/www/html/grafana.proj.db`, `chmod go+r /var/www/html/grafana.proj.db` to be visible from web server.
- Change Grafana admin/admin credentials to something secure!

To enable Grafana anonymous login, do the following:
- Edit Grafana config file: `/etc/grafana/grafana.ini` or `/usr/local/share/grafana/conf/defaults.ini` or `/usr/local/etc/grafana/grafana.ini`:
- Make sure you have options enabled (replace `XYZ`: with your organization name):
```
[auth.anonymous]
enabled = true
org_name = XYZ
org_role = Read Only Editor
```

To enable Google analytics:
google_analytics_ua_id = UA-XXXXXXXXX-Y
- Restart grafana server.

To restrict using GRAFANA by server IP, for example 147.72.202.77:3000, you can set:
- `http_addr = 127.0.0.1`

This will only allow accessing Grafana from Apache proxy, please also see:
- [APACHE.md](https://github.com/cncf/devstats/blob/master/APACHE.md)
- [SSL.md](https://github.com/cncf/devstats/blob/master/SSL.md)

** This will *not* work for Grafana(s) running inside docker containers. **
To disallow access to docker containers from outside world you have to specify port mapping that only exposes port to localhost:
- Instead `-p 3001:3000` (that exposes 3001 to 0.0.0.0) use `127.0.0.1:3001`.

- To run multiple Grafana instances (for example to have multiple projects on the same host), you need to use Docker.
- Instructions here [MULTIPROJECT.md](https://github.com/cncf/devstats/blob/master/MULTIPROJECT.md).
- If want to secure InfluxDB and use Docker at the same time please see: [SECURE_INFLUXDB.md](https://github.com/cncf/devstats/blob/master/SECURE_INFLUXDB.md).
### [INSTALL_UBUNTU16](https://github.com/cncf/devstats/blob/master/INSTALL_UBUNTU16.md)
# devstats installation on Ubuntu

Prerequisites:
- Ubuntu 16.04 LTS (quite old, but longest support).
- Some of the operations below can be CPU/RAM intensive. It is recommended to use a minimum of 8 cores and 30GB RAM or higher.
- Make sure you have enough disk space for both databases - postgresql and influxdb. This tutorial used 50GB. 
- [golang](https://golang.org), this tutorial uses Go 1.9 - [link](https://github.com/golang/go/wiki/Ubuntu)
    - `sudo apt-get update`
    - `sudo apt-get install golang-1.9-go git psmisc jsonlint yamllint gcc`
    - `sudo ln -s /usr/lib/go-1.9 /usr/lib/go`
    - `mkdir $HOME/data; mkdir $HOME/data/dev`
1. Configure Go:
    - For example add to `~/.bash_profile` and/or `~/.profile`:
     ```
     GOROOT=/usr/lib/go; export GOROOT
     GOPATH=$HOME/data/dev; export GOPATH
     PATH=$PATH:$GOROOT/bin:$GOPATH/bin; export PATH
     ```
    - Logout and login again.
    - [golint](https://github.com/golang/lint): `go get -u github.com/golang/lint/golint`
    - [goimports](https://godoc.org/golang.org/x/tools/cmd/goimports): `go get golang.org/x/tools/cmd/goimports`
    - [goconst](https://github.com/jgautheron/goconst): `go get github.com/jgautheron/goconst/cmd/goconst`
    - [usedexports](https://github.com/jgautheron/usedexports): `go get github.com/jgautheron/usedexports`
    - [errcheck](https://github.com/kisielk/errcheck): `go get github.com/kisielk/errcheck`
    - Go InfluxDB client: install with: `go get github.com/influxdata/influxdb/client/v2`
    - Go Postgres client: install with: `go get github.com/lib/pq`
    - Go unicode text transform tools: install with: `go get golang.org/x/text/transform` and `go get golang.org/x/text/unicode/norm`
    - Go YAML parser library: install with: `go get gopkg.in/yaml.v2`
    - Go GitHub API client: `go get github.com/google/go-github/github`
    - Go OAuth2 client: `go get golang.org/x/oauth2`

2. Go to $GOPATH/src/ and clone devstats there:
    - `git clone https://github.com/cncf/devstats.git`
    - If you want to make changes and PRs, please clone `devstats` from GitHub UI, and clone your forked version instead, like this: `git clone https://github.com/your_github_username/devstats.git`

3. Go to devstats directory, so you are in `$GOPATH/src/devstats` directory and compile binaries:
    - `make`

4. If compiled sucessfully then execute test coverage that doesn't need databases:
    - `make test`
    - Tests should pass.

5. Install binaries & metrics:
    - `sudo make install`
    - If go is not installed for root, run the following:
      - `sudo mkdir /etc/gha2db`
      - `sudo chmod 777 /etc/gha2db`
      - `make install`

6. Install Postgres database ([link](https://gist.github.com/sgnl/609557ebacd3378f3b72)):
    - apt-get install postgresql 
    - sudo -i -u postgres
    - psql
    - Postgres only allows local connections by default so it is secure, we don't need to disable external connections:
    - Instructions to enable external connections (not recommended): `http://www.thegeekstuff.com/2014/02/enable-remote-postgresql-connection/?utm_source=tuicool`

7. Inside psql client shell:
    - `create database gha;`
    - `create database devstats;`
    - `create user gha_admin with password 'your_password_here';`
    - `grant all privileges on database "gha" to gha_admin;`
    - `grant all privileges on database "devstats" to gha_admin;`
    - `alter user gha_admin createdb;`
    - Leave the shell and create logs table for devstats: `sudo -u postgres psql devstats < util_sql/devstats_log_table.sql`.

8. Leave `psql` shell, and get newest Kubernetes database dump:
    - `wget https://devstats.cncf.io/gha.dump`.
    - `sudo -u postgres pg_restore -d gha gha.dump` (restore DB dump)
    - Create `ro_user` via `PG_PASS=... ./devel/create_ro_user.sh`

9. Install InfluxDB time-series database ([link](https://docs.influxdata.com/influxdb/v0.9/introduction/installation/)):
    - Ubuntu 16 contains very old `influxdb` when installed by default `apt-get install influxdb`, so:
    - `curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -`
    - `source /etc/lsb-release`
    - `echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list`
    - `sudo apt-get update && sudo apt-get install influxdb`
    - `sudo service influxdb start`
    - Create InfluxDB user, database: `IDB_HOST="localhost" IDB_PASS='your_password_here' IDB_PASS_RO='ro_user_password' ./grafana/influxdb_setup.sh gha`
    - InfluxDB has authentication disabled by default.
    - Edit config file `vim /usr/local/etc/influxdb.conf` and change section `[http]`: `auth-enabled = true`, `max-body-size = 0`, `[subscriber]`: `http-timeout = "300s"`, `write-concurrency = 96`, `[coordinator]`: `write-timeout = "60s"`.
    - If you want to disable external InfluxDB access (for any external IP, only localhost) follow those instructions [SECURE_INFLUXDB.md](https://github.com/cncf/devstats/blob/master/SECURE_INFLUXDB.md).
    - `sudo service influxdb restart`

10. Databases installed, you need to test if all works fine, use database test coverage:
    - `GHA2DB_PROJECT=kubernetes IDB_DB=dbtest IDB_HOST="localhost" IDB_PASS=your_influx_pwd PG_DB=dbtest PG_PASS=your_postgres_pwd make dbtest`
    - Tests should pass.

11. We have both databases running and Go tools installed, let's try to sync database dump from k8s.devstats.cncf.io manually:
    - Set reuse TCP connections (Golang InfluxDB may need this under heavy load): `sudo ./scripts/net_tcp_config.sh`
    - On some VMs `tcp_tw_recycle` will be unavailable, ignore the warning.
    - We need to prefix call with GHA2DB_LOCAL to enable using tools from "./" directory
    - You need to have GitHub OAuth token, either put this token in `/etc/github/oauth` file or specify token value via GHA2DB_GITHUB_OAUTH=deadbeef654...10a0 (here you token value)
    - If you really don't want to use GitHub OAuth2 token, specify `GHA2DB_GITHUB_OAUTH=-` - this will force tokenless operation (via public API), it is a lot more rate limited than OAuth2 which gives 5000 API points/h
    - To import data for the first time (Influx database is empty and postgres database is at the state when Kubernetes SQL dump was made on [k8s.devstats.cncf.io](https://k8s.devstats.cncf.io)):
    - `IDB_HOST="localhost" IDB_PASS=pwd PG_PASS=pwd ./kubernetes/reinit_all.sh`
    - This can take a while (depending how old is psql dump `gha.sql.xz` on [k8s.devstats.cncf.io](https://k8s.devstats.cncf.io). It is generated daily at 3:00 AM UTC.
    - Command should be successfull.

12. We need to setup cron job that will call sync every hour (10 minutes after 1:00, 2:00, ...)
    - You need to open `crontab.entry` file, it looks like this for single project setup (this is obsolete, please use `devstats` mode instead):
    ```
    8 * * * * PATH=$PATH:/path/to/your/GOPATH/bin GHA2DB_CMDDEBUG=1 GHA2DB_PROJECT=kubernetes IDB_HOST="localhost" IDB_PASS='...' PG_PASS='...' gha2db_sync 2>> /tmp/gha2db_sync.err 1>> /tmp/gha2db_sync.log
    20 3 * * * PATH=$PATH:/path/to/your/GOPATH/bin cron_db_backup.sh gha 2>> /tmp/gha2db_backup.err 1>> /tmp/gha2db_backup.log
    */5 * * * * PATH=$PATH:/path/to/your/GOPATH/bin GOPATH=/your/gopath GHA2DB_CMDDEBUG=1 GHA2DB_PROJECT_ROOT=/path/to/repo PG_PASS="..." GHA2DB_SKIP_FULL_DEPLOY=1 webhook 2>> /tmp/gha2db_webhook.err 1>> /tmp/gha2db_webhook.log
    ```
    - For multiple projects you can use `devstats` instead of `gha2db_sync` and `cron/cron_db_backup_all.sh` instead of `cron/cron_db_backup.sh`.
    ```
    7 * * * * PATH=$PATH:/path/to/GOPATH/bin IDB_HOST="localhost" IDB_PASS="..." PG_PASS="..." devstats 2>> /tmp/gha2db_sync.err 1>> /tmp/gha2db_sync.log
    30 3 * * * PATH=$PATH:/path/to/GOPATH/bin cron_db_backup_all.sh 2>> /tmp/gha2db_backup.err 1>> /tmp/gha2db_backup.log
    */5 * * * * PATH=$PATH:/path/to/GOPATH/bin GOPATH=/go/path GHA2DB_CMDDEBUG=1 GHA2DB_PROJECT_ROOT=/path/to/repo GHA2DB_DEPLOY_BRANCHES="production,master" PG_PASS=... GHA2DB_SKIP_FULL_DEPLOY=1 webhook 2>> /tmp/gha2db_webhook.err 1>> /tmp/gha2db_webhook.log
    ```
    - First crontab entry is for automatic GHA sync.
    - Second crontab entry is for automatic daily backup of GHA database.
    - Third crontab entry is for Continuous Deployment - this a Travis Web Hook listener server, it deploys project when specific conditions are met, details [here](https://github.com/cncf/devstats/blob/master/CONTINUOUS_DEPLOYMENT.md).
    - You need to change "..." PG_PASS, IDB_HOST and IDB_PASS to the real postgres password value and copy this line.
    - You need to change "/path/to/your/GOPATH/bin" to the value of "$GOPATH/bin", you cannot use $GOPATH in crontab directly.
    - Run `crontab -e` and put this line at the end of file and save.
    - Cron job will update Postgres and InfluxDB databases at 0:10, 1:10, ... 23:10 every day.
    - It outputs logs to `/tmp/gha2db_sync.out` and `/tmp/gha2db_sync.err` and also to gha Postgres database: into table `gha_logs`.
    - Check database values and logs about 15 minutes after full hours, like 14:15:
    - Check max event created date: `select max(created_at) from gha_events` and logs `select * from gha_logs order by dt desc limit 20`.

13. Install [Grafana](http://docs.grafana.org/installation/mac/) or use Docker to enable multiple Grafana instances, see [MULTIPROJECT.md](https://github.com/cncf/devstats/blob/master/MULTIPROJECT.md).
    - Follow: http://docs.grafana.org/installation/debian/
    - `wget https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana_4.5.1_amd64.deb`
    - `sudo apt-get install -y adduser libfontconfig`
    - `sudo dpkg -i grafana_4.5.1_amd64.deb`
    - `sudo service grafana-server start`
    - Configure Grafana, as described [here](https://github.com/cncf/devstats/blob/master/GRAFANA.md).
    - `service grafana-server restart`
    - Go to Grafana UI (localhost:3000), choose sign out, and then access localhost:3000 again. You should be able to view dashboards as a guest. To login again use http://localhost:3000/login.
    - Install Apache as described [here](https://github.com/cncf/devstats/blob/master/APACHE.md).
    - You can also enable SSL, to do so you need to follow SSL instruction in [SSL](https://github.com/cncf/devstats/blob/master/SSL.md) (that requires domain name).

14. To change all Grafana page titles (starting with "Grafana - ") and icons use this script:
    - `GRAFANA_DATA=/usr/share/grafana/ ./grafana/{{project}}/change_title_and_icons.sh`.
    - `GRAFANA_DATA` can also be `/usr/share/grafana.prometheus/` for example, see [MULTIPROJECT.md](https://github.com/cncf/devstats/blob/master/MULTIPROJECT.md).
    - Replace `GRAFANA_DATA` with your Grafana data directory.
    - `service grafana-server restart`
    - In some cases browser and/or Grafana cache old settings in this case temporarily move Grafana's `settings.js` file:
    - `mv /usr/share/grafana/public/app/core/settings.js /usr/share/grafana/public/app/core/settings.js.old`, restart grafana server and restore file.

15. To enable Continuous deployment using Travis, please follow instructions [here](https://github.com/cncf/devstats/blob/master/CONTINUOUS_DEPLOYMENT.md).

16. You can create new metrics (as SQL files and YAML definitions) and dashboards in Grafana (export as JSON).
17. PRs and suggestions are welcome, please create PRs and Issues on the [GitHub](https://github.com/cncf/devstats).

# More details
- [Local Development](https://github.com/cncf/devstats/blob/master/DEVELOPMENT.md).
- [README](https://github.com/cncf/devstats/blob/master/README.md)
- [USAGE](https://github.com/cncf/devstats/blob/master/USAGE.md)
### [docs/repository_groups](https://github.com/cncf/devstats/blob/master/docs/repository_groups.md)
# Repository groups

- Most project use 'repository groups' to group data under them.
- It is usually defined on the repository level, which means that for example 3 repositories belong to 'repository group 1', and some 2 others belong to 'repository group 2'.
- They can also be defined on the file level, meaning that some files from some repos can belong to a one repository group, while others belong to the other repository group.
- Only Kubernetes project uses 'file level granularity' repository groups definitions.
- For Kubernetes they are defined in main postgres script: [kubernetes/psql.sh](https://github.com/cncf/devstats/blob/master/kubernetes/psql.sh#L13).
- It uses [kubernetes/setup_repo_groups.sh](https://github.com/cncf/devstats/blob/master/kubernetes/setup_repo_groups.sh).
- It finally eecutes this SQL script: [scripts/kubernetes/repo_groups.sql](https://github.com/cncf/devstats/blob/master/scripts/kubernetes/repo_groups.sql).
- It defines repository groups for given repository names.
- The file level granularity part is: [kubernetes/psql.sh](https://github.com/cncf/devstats/blob/master/kubernetes/psql.sh#L14).
- This setup postprocessing scripts:
- One is [kubernetes/setup_scripts.sh](https://github.com/cncf/devstats/blob/master/kubernetes/setup_scripts.sh#L5-L6) which adds postprocess script:
- [util_sql/repo_groups_postprocess_script.sql](https://github.com/cncf/devstats/blob/master/util_sql/repo_groups_postprocess_script.sql) which finally executes: [util_sql/postprocess_repo_groups.sql](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_repo_groups.sql) every hour.
- This SQL updates `gha_events_commits_files` table (see table info [here](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events_commits_files.md)) by setting repository group based on file path, for example:
- These [lines](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_repo_groups.sql#L10-L12) are setting repo group based on full path including repo name, and they set different repo group than defined for `kubernetes/kubernetes` (`Cluster lifecycle` instead of `Kubernetes`).
- These [lines](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_repo_groups.sql#L23-L34) are setting repo group based on PR review comments on specific files in specific repository (also overriding `Kubernetes` with `Cluster lifecycle`).
- Another is [kubernetes/setup_scripts.sh](https://github.com/cncf/devstats/blob/master/kubernetes/setup_scripts.sh#L7-L8) which adds postprocess script (this is used in all projects, not only K8s):
- [util_sql/repo_groups_postprocess_script_from_repos.sql](https://github.com/cncf/devstats/blob/master/util_sql/repo_groups_postprocess_script_from_repos.sql) which finally executes: [util_sql/postprocess_repo_groups_from_repos.sql](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_repo_groups_from_repos.sql).
```
update
  gha_events_commits_files ecf
set
  repo_group = r.repo_group
from
  gha_repos r
where
  r.name = ecf.dup_repo_name
  and r.repo_group is not null
  and ecf.repo_group is null;
```
- It updates `gha_events_commits_files` table (see table info [here](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events_commits_files.md)) setting the same repo group as given file's repository's repo group when file's repoository's repo group is defined and when file's repo group is not yet defined.
- Important part is to update only where commit's file's repo group [is not yet set](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_repo_groups_from_repos.sql#L11) and only when commit's file's repository has [repo group set](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_repo_groups_from_repos.sql#L10).
- Generally all postprocess scripts that run every hour are defined in the table `gha_postprocess_scripts` (see table info [here](https://github.com/cncf/devstats/blob/master/docs/tables/gha_postprocess_scripts.md)), currently: repo groups, labels, texts, PRs, issues.
- More info about `gha_repos` table [here](https://github.com/cncf/devstats/blob/master/docs/tables/gha_repos.md).

# Other projects
- Non Kubernetes projects are not setting `util_sql/repo_groups_postprocess_script.sql`, for example Prometheus uses [this](https://github.com/cncf/devstats/blob/master/prometheus/setup_scripts.sh). Note missing [util_sql/postprocess_repo_groups.sql](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_repo_groups.sql) part.
- It only adds [util_sql/repo_groups_postprocess_script_from_repos.sql](https://github.com/cncf/devstats/blob/master/util_sql/repo_groups_postprocess_script_from_repos.sql), which executes [util_sql/postprocess_repo_groups_from_repos.sql](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_repo_groups_from_repos.sql).
- So it only updates `gha_events_commits_file` table with repository group as defined by commit's file's repository (if defined).
### [docs/vars](https://github.com/cncf/devstats/blob/master/docs/vars.md)
# InfluxDB and PostgreSQL vars

# Influx variables

- Results are saved to InfluxDB tags
- Per project variables can be defined [here](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/idb_vars.yaml) (kubernetes example).
- This is `metrics/{{project_name}}/idb_vars.yaml` for other projects.
- They use `idb_vars` [tool](https://github.com/cncf/devstats/blob/master/cmd/idb_vars/idb_vars.go), called [here](https://github.com/cncf/devstats/blob/master/kubernetes/reinit_all.sh#L4) (Kubernetes) or [here](https://github.com/cncf/devstats/blob/master/prometheus/reinit.sh#L4) (Prometheus).
- `idb_vars` can also be used for defining per project variables using OS commands results.
- To use command result just provide `command: [your_command, arg1, ..., argN]` in `idb_vars.yaml` file. It will overwrite value if command result is non-empty.

# Postgres variables

- Results are saved to [gha_vars](https://github.com/cncf/devstats/blob/master/docs/tables/gha_vars.md) table.
- Key is `name`, values are various columns starting with `value_` - different types are supported.
- Per project variables can be defined [here](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/pdb_vars.yaml) (kubernetes example).
- This is `metrics/{{project_name}}/pdb_vars.yaml` for other projects.
- They use `pdb_vars` [tool](https://github.com/cncf/devstats/blob/master/cmd/pdb_vars/pdb_vars.go), called [here](https://github.com/cncf/devstats/blob/master/kubernetes/psql.sh#L26) (Kubernetes) or [here](https://github.com/cncf/devstats/blob/master/prometheus/psql.sh#L22) (Prometheus).
- `pdb_vars` can also be used for defining per project variables using OS commands results.
- To use command result just provide `command: [your_command, arg1, ..., argN]` in `pdb_vars.yaml` file. It will overwrite value if command result is non-empty.
- It can use previous variables by defining `replaces: [[from1, to1], .., [fromN, toN]]`.
- If `from` is `fromN` and `to` is `toN` - then it will replace `[[fromN]]` with:
  - Already defined variable contents `toN` if no special charactes before variable name are used.
  - Environment variable `toN` if used special syntax `$toN`.
  - Direct string value `toN` if used special syntax `:toN`.
- If `from` starts with `:`, `:from` - then it will replace `from` directly, instead of `[[from]]`. This allows replace any text, not only template variables.
- Any replacement `f` -> `t` made creates additional variable `f` with value `t` that can be used in next replacements or next variables.
- All those options are used [here](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/pdb_vars.yaml), [here](https://github.com/cncf/devstats/blob/master/metrics/prometheus/pdb_vars.yaml) or [there](https://github.com/cncf/devstats/blob/master/metrics/opencontainers/pdb_vars.yaml).
- We can even create conditional partial (conditional on variable name, in this case `hostname`). See this:
```
  - [hostname, os_hostname]
  #- [hostname, ':devstats.cncf.io']
  - [':testsrv=cncftest.io ', ':']
  - [': cncftest.io=testsrv', ':']
  - [':testsrv=', ':<!-- ']
  - [':=testsrv', ': -->']
  - [':prodsrv=devstats.cncf.io ', ':']
  - [': devstats.cncf.io=prodsrv', ':']
  - [':prodsrv=', ':<!-- ']
  - [':=prodsrv', ': -->']
```
- Assume we already have `os_hostname` variable which contains current hostname.
- In first line we replace all `[[hostname]]` with current host name.
- Second line is commented out, but here we're replacing `[[hostname]]` with hardcoded value. We can comment out 1st line and uncomment 2nd to test how it would work on a specific hostname.
- We can use 'test server' markers: `testsrv=[[hostname]] ` and ` [[hostname]]=testsrv` to mark beginning and end of content that will only be inserted when `hostname = 'cncftest.io'`.
- We can use 'production server' markers: `prodsrv=[[hostname]] ` and ` [[hostname]]=prodsrv` to mark beginning and end of content that will only be inserted when `hostname = 'devstats.cncf.io'`.
- See home dashboard projects [panel](https://github.com/cncf/devstats/blob/master/partials/projects.html) for example usage.
- This works like this:
  - Text `testsrv=[[hostname]]` is first replaced with the current hostname, for example: `testsrv=cncftest.io` on the test server.
  - Then we have a direct replacement (marek by replacements starting with `:`) 'testsrv=cncftest.io ' -> '', so finally entire `testsrv=[[hostname]]` is cleared.
  - Similar story happens with `[[hostname]]=testsrv`.
  - That makes content between those markers directly available.
  - Now let's assume we are on the production server, so `hostname=devstats.cncf.io`.
  - Text `testsrv=[[hostname]]` is first replaced with the current hostname, for example: `testsrv=devstats.cncf.io` on the test server.
  - There is no direct replacement for `:testsrv=devstats.cncf.io` (there only is `:prodsrv=devstats.cncf.io` with this hostname).
  - But there is replacement for nonmatching `testsrv` part: `':testsrv=', ':<!-- '`, so finally `testsrv=[[hostname]]` -> `testsrv=devstats.cncf.io` -> `<!-- devstats.cncf.io`.
  - Similar: `[[hostname]]=testsrv` -> `devstats.cncf.io=testsrv` -> `devstats.cncf.io -->`, using `':=testsrv', ': -->'`.
- So finally `testsrv=[[hostname]]` is cleared on the test server and evaluates to `<!-- devstats.cncf.io` on the production.
- `[[hostname]]=testsrv` is cleared on the test server and evaluates to `devstats.cncf.io -->` on the production.
- `prodsrv=[[hostname]]` is cleared on the production server and evaluates to `<!-- cncftest.io` on the test.
- `[[hostname]]=prodsrv` is cleared on the production server and evaluates to `cncftest.io -->` on the test.
### [docs/tags](https://github.com/cncf/devstats/blob/master/docs/tags.md)
# InfluxDB tags

- You can use InfluxDB tags to define drop-down values (variables) in Grafana dashboards.
- Some drop-downs can be hardcoded, without using influxDB, for example `Period` drop-down is usually [hardcoded](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json#L188-L234) and has the same values as in [metrics.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml#L157-L162).
- The same values means Grafana's variable JSON has the same period definitions as defined by `period`, `aggregate` and `skip` properties of a given metric in `metrics.yaml`.
- Sometimes we need drop-down values to be fetched from InfluxDB, but this is not a time-series data, we're using InfluxDB tags in such cases.
- All tags are defined per project in `idb_tags.yaml` file, for example for Kubernetes it is [metrics/kubernetes/idb_tags.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/idb_tags.yaml).
- For example for "Repository" group we can use [repogroup_name](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json#L235-L254) which uses [this tag](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/idb_tags.yaml#L21).
- Then we can create [repogroup](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json#L255-L274) which uses `repogroup_name` defined above and [this tag](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/idb_tags.yaml#L22).
- One tag returns unprocessed names like `A,A b c, d/e/f` the other returns normalized like `a,a_b_c,d_e_f` which can be used as InfluxDB series name. Example above shows drop down values with unprocessed names, but uses hidden variable that returns current selection normalized for InfluxDB series name in Grafana's data query.
- They both use SQL defined [here](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/idb_tags.yaml#L19) to get vales from Postgres: [metrics/kubernetes/repo_groups_tags_with_all.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/repo_groups_tags_with_all.sql).
- Postgres SQLs that returns data for InfluxDB tags has `tags` in their name, for example `Companies` drop-down tags: [metric/kubernetes/companies_tags.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/companies_tags.sql).
- Some tags use `{{lim}}` template value, this is the number of tag values to return (for most items it is limited to 69), see template evaluation [cmd/idb_tags/idb_tags.go](https://github.com/cncf/devstats/blob/master/cmd/idb_tags/idb_tags.go#L107).
- There is also a special `os_hostname` tag that evaluates to current machine's hostname, it is calculated [here](https://github.com/cncf/devstats/blob/master/cmd/idb_tags/idb_tags.go#L74-L89).
- It can be used to generate links to current host name (production or test), you can use [Grafana variable that uses InfluxDB tag](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json#L421-L438) to use it as link basename, like [here](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json#L84).
- Hostname tag is always available on all projects.
### [docs/annotations](https://github.com/cncf/devstats/blob/master/docs/annotations.md)
# Annotations

- Most dashboards use Grafana's annotations query.
- For example [here](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json#L32-L58).
- It uses InfluxDB data from `annotations` series: `SELECT title, description from annotations WHERE $timeFilter order by time asc`
- `$timeFilter` is managed by Grafana internally and evaluates to current dashboard date range.
- Each project's annotations are computed using data from [projects.yaml](https://github.com/cncf/devstats/blob/master/projects.yaml#L11-L12).
- `main_repo` defines GitHub repository (project can have and usually have multiple GitHub repos) to get annotations from.
- `annotation_regexp` defines RegExp patter to fetch annotations.
- Final annotation list will be a list of tags from `main_repo` that matches `annotation_regexp`.
- Tags are processed by using [git_tags.sh](https://github.com/cncf/devstats/blob/master/git/git_tags.sh) script on a given reposiory.
- Annotations are automatically created using [annotations tool](https://github.com/cncf/devstats/blob/master/cmd/annotations/annotations.go).
- You can force regenerate annotations using `{{projectname}}/annotations.sh` script. For Kubernetes it will be [kubernetes/annotations.sh](https://github.com/cncf/devstats/blob/master/kubernetes/annotations.sh).
- You can also clear all annotations using [devel/clear_all_annotations.sh](https://github.com/cncf/devstats/blob/master/devel/clear_all_annotations.sh) script and generate all annotations using [devel/add_all_annotations.sh](https://github.com/cncf/devstats/blob/master/devel/add_all_annotations.sh) script.
- Pass `ONLY='proj1 proj2'` to limit to the selected list of projects.
- When computing annotations some special InfluxDB series are created:
- `annotations` it conatins all tag names & dates matching `main_repo` and `annotation_regexp` + CNCF join date (if set, check [here](https://github.com/cncf/devstats/blob/master/projects.yaml#L8))
- Example values (for Kubernetes):
```
> precision rfc3339
> select * from annotations
name: annotations
time                 description                              title
----                 -----------                              -----
2014-09-08T23:00:00Z Release Kubernetes v0.2  This commit wil v0.2
2014-09-19T17:00:00Z Rev the version to 0.3                   v0.3
2014-10-14T23:00:00Z Rev the version to 0.4                   v0.4
2014-11-17T23:00:00Z Add the 0.5 release.                     v0.5
2014-12-02T00:00:00Z Kubernetes version v0.6.0                v0.6.0
2014-12-16T00:00:00Z Kubernetes version v0.7.0                v0.7.0
2015-01-07T19:00:00Z Kubernetes version v0.8.0                v0.8.0
2015-01-21T03:00:00Z Kubernetes version v0.9.0                v0.9.0
2015-02-03T16:00:00Z Kubernetes version v0.10.0               v0.10.0
2015-02-18T05:00:00Z Kubernetes version v0.11.0               v0.11.0
2015-03-03T04:00:00Z Kubernetes version v0.12.0               v0.12.0
2015-03-16T23:00:00Z Kubernetes version v0.13.0               v0.13.0
2015-03-30T18:00:00Z Kubernetes version v0.14.0               v0.14.0
2015-04-13T21:00:00Z Kubernetes version v0.15.0               v0.15.0
2015-04-29T04:00:00Z Kubernetes version v0.16.0               v0.16.0
2015-05-12T04:00:00Z Kubernetes version v0.17.0               v0.17.0
2015-05-29T16:00:00Z Kubernetes version v0.18.0               v0.18.0
2015-06-10T16:00:00Z Kubernetes version v0.19.0               v0.19.0
2015-06-26T03:00:00Z Kubernetes version v0.20.0               v0.20.0
2015-07-07T21:00:00Z Kubernetes version v0.21.0               v0.21.0
2015-07-11T04:00:00Z Kubernetes version v1.0.0                v1.0.0
2015-09-25T23:00:00Z Kubernetes version v1.1.0                v1.1.0
2016-03-10T00:00:00Z 2016-03-10 - joined CNCF                 CNCF join date
2016-03-16T22:00:00Z Kubernetes version v1.2.0                v1.2.0
2016-07-01T19:00:00Z Kubernetes version v1.3.0                v1.3.0
2016-09-26T18:00:00Z Kubernetes version v1.4.0                v1.4.0
2016-12-12T23:00:00Z Kubernetes version v1.5.0                v1.5.0
2017-03-28T16:00:00Z Kubernetes version v1.6.0                v1.6.0
2017-06-29T22:00:00Z Kubernetes version v1.7.0 file updates   v1.7.0
2017-09-28T22:00:00Z Kubernetes version v1.8.0 file updates   v1.8.0
2017-12-14T19:00:00Z Merge pull request #57174 from liggitt/a v1.9.0
```
- `quick_ranges` this series contain data between proceeding annotations. For example if you have annotations for v1.0 = 2014-01-01, v2.0 = 2015-01-01 and v3.0 = 2016-01-01, it will create ranges: `v1.0 - v2.0` (2014-01-01 - 2015-01-01), `v2.0 - v3.0` (2015-01-01 - 2016-01-01), `v3.0 - now` (2016-01-01 - now).
- So if you have 10 annotations it will create `anno_0_1`, `anno_1_2`, `anno_2_3`, .., `anno_8_9`, `anno_9_now`.
- It will also create special periods: last day, last week, last month, last quarter, last year, last 10 days, last decade (10 years).
- Some of those period have fixed length, not changing in time (all of then not ending now - past ones), those periods will only be calculated once and special marker will be set in the `computed` series to avoid calculating them multiple times.
- This flag (skip past calculation) is the default flag, unless we're full regenerating data, see [this](https://github.com/cncf/devstats/blob/master/cmd/gha2db_sync/gha2db_sync.go#L470-L472).
- Example quick ranges (for Kubernetes):
```
> select * from quick_ranges
name: quick_ranges
time                 quick_ranges_data                                    quick_ranges_name quick_ranges_suffix value
----                 -----------------                                    ----------------- ------------------- -----
2018-02-20T00:00:00Z d;1 day;;                                            Last day          d                   0
2018-02-20T01:00:00Z w;1 week;;                                           Last week         w                   0
2018-02-20T02:00:00Z d10;10 days;;                                        Last 10 days      d10                 0
2018-02-20T03:00:00Z m;1 month;;                                          Last month        m                   0
2018-02-20T04:00:00Z q;3 months;;                                         Last quarter      q                   0
2018-02-20T05:00:00Z y;1 year;;                                           Last year         y                   0
2018-02-20T06:00:00Z y10;10 years;;                                       Last decade       y10                 0
2018-02-20T07:00:00Z anno_0_1;;2014-09-08 23:21:36;2014-09-19 17:11:03    v0.2 - v0.3       anno_0_1            0
2018-02-20T08:00:00Z anno_1_2;;2014-09-19 17:11:03;2014-10-14 23:46:22    v0.3 - v0.4       anno_1_2            0
2018-02-20T09:00:00Z anno_2_3;;2014-10-14 23:46:22;2014-11-17 23:01:09    v0.4 - v0.5       anno_2_3            0
2018-02-20T10:00:00Z anno_3_4;;2014-11-17 23:01:09;2014-12-02 00:26:48    v0.5 - v0.6.0     anno_3_4            0
2018-02-20T11:00:00Z anno_4_5;;2014-12-02 00:26:48;2014-12-16 00:57:39    v0.6.0 - v0.7.0   anno_4_5            0
2018-02-20T12:00:00Z anno_5_6;;2014-12-16 00:57:39;2015-01-07 19:22:53    v0.7.0 - v0.8.0   anno_5_6            0
2018-02-20T13:00:00Z anno_6_7;;2015-01-07 19:22:53;2015-01-21 03:50:24    v0.8.0 - v0.9.0   anno_6_7            0
2018-02-20T14:00:00Z anno_7_8;;2015-01-21 03:50:24;2015-02-03 16:30:13    v0.9.0 - v0.10.0  anno_7_8            0
2018-02-20T15:00:00Z anno_8_9;;2015-02-03 16:30:13;2015-02-18 05:15:37    v0.10.0 - v0.11.0 anno_8_9            0
2018-02-20T16:00:00Z anno_9_10;;2015-02-18 05:15:37;2015-03-03 04:04:24   v0.11.0 - v0.12.0 anno_9_10           0
2018-02-20T17:00:00Z anno_10_11;;2015-03-03 04:04:24;2015-03-16 23:31:03  v0.12.0 - v0.13.0 anno_10_11          0
2018-02-20T18:00:00Z anno_11_12;;2015-03-16 23:31:03;2015-03-30 18:02:57  v0.13.0 - v0.14.0 anno_11_12          0
2018-02-20T19:00:00Z anno_12_13;;2015-03-30 18:02:57;2015-04-13 21:08:45  v0.14.0 - v0.15.0 anno_12_13          0
2018-02-20T20:00:00Z anno_13_14;;2015-04-13 21:08:45;2015-04-29 04:20:12  v0.15.0 - v0.16.0 anno_13_14          0
2018-02-20T21:00:00Z anno_14_15;;2015-04-29 04:20:12;2015-05-12 04:43:34  v0.16.0 - v0.17.0 anno_14_15          0
2018-02-20T22:00:00Z anno_15_16;;2015-05-12 04:43:34;2015-05-29 16:41:41  v0.17.0 - v0.18.0 anno_15_16          0
2018-02-20T23:00:00Z anno_16_17;;2015-05-29 16:41:41;2015-06-10 16:25:31  v0.18.0 - v0.19.0 anno_16_17          0
2018-02-21T00:00:00Z anno_17_18;;2015-06-10 16:25:31;2015-06-26 03:08:58  v0.19.0 - v0.20.0 anno_17_18          0
2018-02-21T01:00:00Z anno_18_19;;2015-06-26 03:08:58;2015-07-07 21:56:55  v0.20.0 - v0.21.0 anno_18_19          0
2018-02-21T02:00:00Z anno_19_20;;2015-07-07 21:56:55;2015-07-11 04:01:34  v0.21.0 - v1.0.0  anno_19_20          0
2018-02-21T03:00:00Z anno_20_21;;2015-07-11 04:01:34;2015-09-25 23:40:56  v1.0.0 - v1.1.0   anno_20_21          0
2018-02-21T04:00:00Z anno_21_22;;2015-09-25 23:40:56;2016-03-16 22:01:03  v1.1.0 - v1.2.0   anno_21_22          0
2018-02-21T05:00:00Z anno_22_23;;2016-03-16 22:01:03;2016-07-01 19:19:06  v1.2.0 - v1.3.0   anno_22_23          0
2018-02-21T06:00:00Z anno_23_24;;2016-07-01 19:19:06;2016-09-26 18:09:47  v1.3.0 - v1.4.0   anno_23_24          0
2018-02-21T07:00:00Z anno_24_25;;2016-09-26 18:09:47;2016-12-12 23:29:43  v1.4.0 - v1.5.0   anno_24_25          0
2018-02-21T08:00:00Z anno_25_26;;2016-12-12 23:29:43;2017-03-28 16:23:06  v1.5.0 - v1.6.0   anno_25_26          0
2018-02-21T09:00:00Z anno_26_27;;2017-03-28 16:23:06;2017-06-29 22:53:16  v1.6.0 - v1.7.0   anno_26_27          0
2018-02-21T10:00:00Z anno_27_28;;2017-06-29 22:53:16;2017-09-28 22:13:57  v1.7.0 - v1.8.0   anno_27_28          0
2018-02-21T11:00:00Z anno_28_29;;2017-09-28 22:13:57;2017-12-14 19:20:37  v1.8.0 - v1.9.0   anno_28_29          0
2018-02-21T12:00:00Z anno_29_now;;2017-12-14 19:20:37;2018-02-21 00:00:00 v1.9.0 - now      anno_29_now         0
```
- `computed` this series hold which metrics were already computed, example values (part of Kubernetes values):
```
> select * from computed
name: computed
time                 computed_from       computed_key                           value
----                 -------------       ------------                           -----
2014-09-08T23:00:00Z 2014-09-08 23:21:36 kubernetes/hist_approvers.sql          0
2014-09-08T23:00:00Z 2014-09-08 23:21:36 kubernetes/project_stats.sql           0
2014-09-08T23:00:00Z 2014-09-08 23:21:36 kubernetes/project_developer_stats.sql 0
2014-09-08T23:00:00Z 2014-09-08 23:21:36 kubernetes/project_company_stats.sql   0
2014-09-08T23:00:00Z 2014-09-08 23:21:36 kubernetes/pr_workload_table.sql       0
```
- Key is `computed_key` - metric file name and `computed_from` that holds `date from` for calculated period. Checking and setting `computed` state happens [here](https://github.com/cncf/devstats/blob/master/cmd/db2influx/db2influx.go#L310-L346).
- Logic to decide when we can skip calculations is [here](https://github.com/cncf/devstats/blob/master/cmd/db2influx/db2influx.go#L387), [here](https://github.com/cncf/devstats/blob/master/cmd/db2influx/db2influx.go#L398) and [here](https://github.com/cncf/devstats/blob/master/cmd/db2influx/db2influx.go#L585).
- Period calculation (this is also for charts not only histograms) is determined [here](https://github.com/cncf/devstats/blob/master/time.go#L44). Possible period values are: `h,d,w,m,q,y,hN,dN,wN,mN,qN,yN,anno_x_y,anno_x_now`: h..y -mean hour..year, hN, N > 1, means some aggregation of h..y, anno_x_y (x >= 0, y > x) mean past quick range, anno_x_now (x >=0) mean last quick range.
- You can use: `influx -host localhost -username gha_admin -password pwd -database gha` to access Kubernetes InfluxDB to see those values: `precision rfc3339`, `select * from {{seriesname}}`, `{{seriesname}}` being: `quick_ranges`, `computed`, `annotations`.
- `main_repo` and `annotation_regexp` can be empty (like for 'All' project [here](https://github.com/cncf/devstats/blob/master/projects.yaml#L202-L207). Depending on CNCF join date presence you will see single annotation or none then.
### [docs/tables/gha_postprocess_scripts](https://github.com/cncf/devstats/blob/master/docs/tables/gha_postprocess_scripts.md)
# `gha_postprocess_scripts` table

- This is a special table, not created by any GitHub archive (GHA) event.
- It contains informations about which scripts should be executed every hour after data from GitHub archives is fetched for the next hour.
- Records in this table are inserted once, as a part of `{{project_name}}/psql.sh` (for Kubernetes it is [kubernetes/psql.sh](https://github.com/cncf/devstats/blob/master/kubernetes/psql.sh#L14)).
- For every project `{{project_name}}/setup_scripts.sh` is used to add records to this table (for Kubernetes it is [kubernetes/setup_scripts.sh](https://github.com/cncf/devstats/blob/master/kubernetes/setup_scripts.sh)).
- It contains just few records (5 for Kubernetes, 4 for other projects).
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L1031-L1043).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L538-L541).
- This table is used to create/update values in [gha_issues_events_labels](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues_events_labels.md), [gha_texts](https://github.com/cncf/devstats/blob/master/docs/tables/gha_texts.md), [gha_events_commits_files](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events_commits_files.md), [gha_issues_pull_requests](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues_pull_requests.md).
- This table is used by [this code](https://github.com/cncf/devstats/blob/master/structure.go#L1162-L1187) get postprocess scripts to run.
- Default postprocess scripts are defined by [kubernetes/setup_scripts.sh](https://github.com/cncf/devstats/blob/master/kubernetes/setup_scripts.sh#L4). This is `{{projectname}}/setup_scripts.sh` for other projects.
- Its primary key is `(ord, path)`.

# Columns

- `ord`: Ordinal number used to decide order of scripts to run.
- `path`: Script path, for example `util_sql/postprocess_repo_groups.sql`.
### [docs/tables/gha_issues_labels](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues_labels.md)
# `gha_issues_labels` table

- This is a table that holds labels set on an issue/PR in a given moment in time.
- GitHub is not generating any events when label set on an issue/PR changes (adding, removing labels).
- When next event (like issue comment) on that issue happens (which can happen a month later) this table will contain new labels set.
- This is a variable table, for details check [variable table](https://github.com/cncf/devstats/blob/master/docs/tables/variable_table.md).
- It contains about 3.7M records as of Mar 2018.
- [ghaapi2db](https://github.com/cncf/devstats/tree/master/cmd/ghapi2db/ghapi2db.go) tool is creating new labels set entries when it detects that some issue/PR has wrong labels set or wrong milestone.
- It happens when somebody changes label and/or milestone without commenting on the issue, or after commenting. Change label/milestone is not creating any GitHub event, so the final issue/PR state can be wrong.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L533-L554).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L354-L366).
- Its primary key is `(event_id, issue_id, label_id)`.

# Columns

Columns starting with `dup_` are duplicated from other tables, to speedup processing and allow saving joins.
- `issue_id`: Issue ID, see [gha_issues](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues.md).
- `event_id`: GitHub event ID, see [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md).
- `label_id`: Label ID, see [gha_labels](https://github.com/cncf/devstats/blob/master/docs/tables/gha_labels.md).
- `dup_actor_id`: GitHub actor ID (GitHub event creator - usually issue comment creator, not necesarilly someone who addded/removed label), see [gha_actors](https://github.com/cncf/devstats/blob/master/docs/tables/gha_actors.md).
- `dup_actor_login`: Duplicated GitHub actor login (from [gha_actors](https://github.com/cncf/devstats/blob/master/docs/tables/gha_actors.md) table).
- `dup_repo_id`: GitHub repository ID, see [gha_repos](https://github.com/cncf/devstats/blob/master/docs/tables/gha_repos.md).
- `dup_repo_name`: Duplicated GitHub repository name (note that repository name can change in time, but repository ID remains the same, see [gha_repos](https://github.com/cncf/devstats/blob/master/docs/tables/gha_repos.md) table).
- `dup_type`: GitHub event type, can be: PullRequestReviewCommentEvent, MemberEvent, PushEvent, ReleaseEvent, CreateEvent, GollumEvent, TeamAddEvent, DeleteEvent, PublicEvent, ForkEvent, PullRequestEvent, IssuesEvent, WatchEvent, IssueCommentEvent, CommitCommentEvent.
- `dup_created_at`: Event creation date.
- `dup_issue_number`: Issue number, see [gha_issues](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues.md).
- `dup_label_name`: Label name, see [gha_labels](https://github.com/cncf/devstats/blob/master/docs/tables/gha_labels.md).
### [docs/tables/gha_pull_requests](https://github.com/cncf/devstats/blob/master/docs/tables/gha_pull_requests.md)
# `gha_pull_requests` table

- This is a table that holds GitHub PR state at a given point in time (`event_id` refers to [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md)).
- This is a variable table, for details check [variable table](https://github.com/cncf/devstats/blob/master/docs/tables/variable_table.md).
- It contains about 403K records but only 76K distinct PR IDs (Mar 2018 state) - this means that there are about 5-6 events per PR on average.
- Its primary key is `(event_id, id)`.
- There is a special [compute table](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues_pull_requests.md) that connects Issues with PRs.

# Columns

Most important columns are:
- `id`: GitHub Pull Request ID.
- `event_id`: GitHub event ID, see [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md).
- `body`: PR text.
- `created_at`: PR creation date.
- `closed_at`: PR close date. Note that this table holds PR state in time, so for some event this date will be null, for some other it will be set.
- `merged_at`: PR merge date (can be null for all events). Note that this table holds PR state in time, so for some event this date will be null, for some other it will be set.
- `user_id`: GitHub user ID performing action on the issue.
- `milestone_id`: Milestone ID, see [gha_milestones](https://github.com/cncf/devstats/blob/master/docs/tables/gha_milestones.md).
- `number`: PR number - this is an unique number within single repository. There will be an entry in [gha_issues_pull_requests](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues_pull_requests.md) and [gha_issues](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues.md) with the same `number` and `repo_id` - PRs are stored on that tables too.
- `state`: `open` or `closed` at given GitHub event `event_id` date.
- `merged`: PR merged state at given `event_id` time, can be true (merged) or false, null (not merged).
- `merged_by_id`: GitHub user who merged this PR or null.
- `merge_commit_sha`: SHA of a merge commit, if merged, see [gha_commits](https://github.com/cncf/devstats/blob/master/docs/tables/gha_commits.md).
- `title`: Issue title.
- `assignee_id`: Assigned GitHub user, can be null.
- `base_sha`: PRs base branch SHA, see [gha_commits](https://github.com/cncf/devstats/blob/master/docs/tables/gha_commits.md).
- `head_sha`: PRs SHA, see [gha_commits](https://github.com/cncf/devstats/blob/master/docs/tables/gha_commits.md).
### [docs/tables/const_table](https://github.com/cncf/devstats/blob/master/docs/tables/const_table.md)
# Const table

- Tables marked as `const` are not changing in time.
- Their values are inserted once and are not updated anymore.
- Such tables does not contain reference to GitHub event.
### [docs/tables/gha_milestones](https://github.com/cncf/devstats/blob/master/docs/tables/gha_milestones.md)
# `gha_milestones` table

- This is a table that holds GitHub milestone state at a given point in time (`event_id` refers to [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md)).
- This is a variable table, for details check [variable table](https://github.com/cncf/devstats/blob/master/docs/tables/variable_table.md).
- It contains about 265K records but only 351 distinct milestone IDs (Mar 2018 state) - this means that there are about 750 events per milestone on average.
- Its primary key is `(event_id, id)`.

# Columns

Most important columns are:
- `id`: GitHub milestone ID.
- `event_id`: GitHub event ID, see [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md).
- `description`: milestone description.
- `created_at`: Milestone creation date.
- `closed_at`: Milestone close date. Note that this table holds milestone state in time, so for some event this date will be null, for some other it will be set.
- `due_at`: Milestone due date. Note that this table holds milestone state in time, so  this date can change in time (for example when milestone due date is moved to next month etc.).
- `number`: Milestone number.
- `state`: `open` or `closed` at given GitHub event `event_id` date.
- `title`: Milestone title.
- `creator_id`: GitHub user ID who created this milestone.
- `closed_issues`: number of issues closed for this milestone at given point of time `event_id`.
- `open_issues`: number of open issues for this milestone at given point of time `event_id`.
### [docs/tables/gha_repos](https://github.com/cncf/devstats/blob/master/docs/tables/gha_repos.md)
# `gha_repos` table

- This table holds GitHub repositories.
- This is a const table, values are inserted once and doesn't change, see [const table](https://github.com/cncf/devstats/blob/master/docs/tables/const_table.md).
- Repos are created during standard GitHub archives import from JSON [here](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L34-L44).
- Repo can change name in time, but repo ID remains the same in this case.
- Repositories have special groupping columns: `alias` and `repo_group`. Alias can be used to group the same repo (different names in time but the same ID) under the same "alias".
- `repo_group` is used in many dashboards to grroup similar repositories under some special name. Repository groups are setup once by `{{project_name}}/setup_repo_groups.sh`.
- For Kubernetes it is: [kubernetes/psql.sh](https://github.com/cncf/devstats/blob/master/kubernetes/psql.sh#L13)). It calls [kubernetes/setup_repo_groups.sh](https://github.com/cncf/devstats/blob/master/kubernetes/setup_repo_groups.sh)
- This in turn executes SQL script: [scripts/kubernetes/repo_groups.sql](https://github.com/cncf/devstats/blob/master/scripts/kubernetes/repo_groups.sql). Each project can have its own project-specific aliases/repo groups definitions.
- It contains 135 records as of Mar 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L137-L157).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L665-L672).
- Its primary key is `(id, name)`.
- Values from this table are often duplicated in other tables (to speedup processing) as `dup_repo_id`, `dup_repo_name`.

# Columns

- `id`: GitHub repository ID.
- `name`: GitHub repository name, can change in time, but ID remains the same then.
- `org_id`: GitHub organization ID (can be null) see [gha_orgs](https://github.com/cncf/devstats/blob/master/docs/tables/gha_orgs.md).
- `org_login`: GitHub organization name duplicated from `gha_orgs` table (can be null). This can be organization name or GitHub username.
- `repo_group`: Artificial column, updated by specific per-project scripts.
- `alias`: Artificial column, updated by specific per-project scripts. Usually used to keep the same name for the same repo, for entire repo name change history.
### [docs/tables/gha_commits](https://github.com/cncf/devstats/blob/master/docs/tables/gha_commits.md)
# `gha_commits` table

- This table contains commits data.
- This is a variable table, for details check [variable table](https://github.com/cncf/devstats/blob/master/docs/tables/variable_table.md).
- Commits are created during the standard GitHub archives import from JSON [here (pre-2015 format)](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L910-L926) and [here (current format)](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L1162-L1178).
- Commit contain actor name (not login) as reported by `git commit`, so it can be difficult to map to a real actor (somebody can have non-standard name on a local computer), but we also have a GitHub login of actor who made a `git push` to a GitHub repository.
- Usually the same person makes commit and push, so this maps "good enough" - we can also search for actor name, but only actors imported by affiliations tool have a name, for details see [actors table](https://github.com/cncf/devstats/blob/master/docs/tables/gha_actors.md).
- It contains about 209K records as of Feb 2018, 148K distinct commit SHAs. It means that there are about 209/148 = 1.41 events/commit. So about 41% of commits are referenced more than once.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L265-L295).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L159-L171).
- Its primary key is `(sha, event_id)`.
- Values from this table are often duplicated in other tables (to speedup processing) as `dup_actor_id`, `dup_actor_login`.

# Columns

- `sha`: commits unique SHA.
- `event_id`: GitHub event ID refering to this commit.
- `author_name`: Author name as provided by commiter when doing `git commit`. This is *NOT* a GitHub login.
- `message`: Commit message.
- `is_distinct`: boolean true/false.

# Duplicates from [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md) table

Those columns duplicate value from a GitHub event refering to this column `event_id`.
- `dup_actor_id`: event's actor ID.
- `dup_actor_login`: event's GitHub login (actor who pushed this commit).
- `dup_repo_id`: event's GitHub repository ID.
- `dup_repo_name`: event's GitHub's repository name (note that repository name can change in thime, while repository ID is not changing).
- `dup_type`: event's type like PushEvent, PullRequestEvent, ...
- `dup_created_at`: event's creation date.
### [docs/tables/gha_orgs](https://github.com/cncf/devstats/blob/master/docs/tables/gha_orgs.md)
# `gha_orgs` table

- This table holds GitHub organizations.
- This is a const table, values are inserted once and doesn't change, see [const table](https://github.com/cncf/devstats/blob/master/docs/tables/const_table.md).
- Orgs are created during standard GitHub archives import from JSON [here](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L47-L60).
- Org name can change name in time (probably?), but organization ID remains the same in this case.
- It contains 6 records as of Mar 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L171-L181).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L472-L475).
- Its primary key is `id`.

# Columns

- `id`: GitHub organization ID.
- `login`: GitHub organization login: it can be organization name (like `kubernetes`) or GitHub user name.
### [docs/tables/gha_issues_events_labels](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues_events_labels.md)
# `gha_issues_events_labels` table

- This is a compute table, that contains shortcuts to issues labels connected with events (for metrics speedup).
- It contains many duplicated columns to allow queries on this single table instead of joins.
- It needs postprocessing that is defined in a standard project's setup script. It is updated in postprocess every hour.
- Setup scripts is called by main Postgres init script, for Kubernetes it is: [kubernetes/psql.sh](https://github.com/cncf/devstats/blob/master/kubernetes/psql.sh#L14)).
- It runs [kubernetes/setup_scripts.sh](https://github.com/cncf/devstats/blob/master/kubernetes/setup_scripts.sh#L4). This is `{{projectname}}/setup_scripts.sh` for other projects.
- SQL script [util_sql/postprocess_labels.sql](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_labels.sql) is scheduled to run every hour by: [util_sql/default_postprocess_scripts.sql](https://github.com/cncf/devstats/blob/master/util_sql/default_postprocess_scripts.sql#L2).
- It is called by [this code](https://github.com/cncf/devstats/blob/master/structure.go#L1162-L1187) that uses [gha_postprocess_scripts](https://github.com/cncf/devstats/blob/master/docs/tables/gha_postprocess_scripts.md) table to get postprocess scripts to run. One of them, defined above creates entries for `gha_issues_events_labels` table every hour.
- It contains about 3.6M records as of Feb 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L1077-L1096).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L333-L345).
- Its primary key is `(issue_id, label_id, event_id)`.
- It contains data from [labels](https://github.com/cncf/devstats/blob/master/docs/tables/gha_labels.md), [issue_labels](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues_labels.md) tables.

# Columns

- `event_id`: GitHub event ID. This ID is artificially generated for pre-2015 events.
- `issue_id`: GitHub issue ID. See [gha_issues](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues.md) table.
- `label_id`: GitHub label ID (can be < 0 for pre-2015 labels). See [gha_labels](https://github.com/cncf/devstats/blob/master/docs/tables/gha_labels.md).
- `label_name`: Label name duplicate from [gha_labels](https://github.com/cncf/devstats/blob/master/docs/tables/gha_gha_labels.md) table.
- `created_at`: Event creation date, comes from [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md).
- `actor_id`: Event's actor name.
- `actor_login`: Event's actor login (this comes from [gha_issues_labels](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues_labels.md) <- [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md) <- [gha_actors](https://github.com/cncf/devstats/blob/master/docs/tables/gha_actors.md).
- `repo_id`: GitHub repository ID (from [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md)).
- `repo_name`: GitHub repository name (note that repository name can change in time, while repository ID cannot).
- `type`: GitHub event type - see [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md) for details.
- `issue_number`: Issue number (this is usually a small number that is unique withing given repository).
### [docs/tables/gha_vars](https://github.com/cncf/devstats/blob/master/docs/tables/gha_vars.md)
# `gha_vars` table

- This is a special table that holds PostgreS variables defined by [pdb_vars](https://github.com/cncf/devstats/blob/master/cmd/prb_vars/pdb_vars.go) tool.
- More info about `pdb_vars` tool [here](https://github.com/cncf/devstats/blob/master/docs/vars.md).
- Key is `name`, values are various columns starting with `value_` - different types are supported.
- Per project variables can be defined [here](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/pdb_vars.yaml) (kubernetes example).
- Its primary key is `name`. Max length is 100 characters.

# Columns

- `name`: Variable name. Max var name length is 100 characters.
- `value_i`: Integer value. Bigint.
- `value_f`: Float value. Double precision.
- `value_s`: String value. Unlimited length.
- `value_dt`: Datetime value. 
### [docs/tables/gha_texts](https://github.com/cncf/devstats/blob/master/docs/tables/gha_texts.md)
# `gha_texts` table

- This is a special table, not created by any GitHub archive (GHA) event. Its purpose is to hold all texts entered by all actors on all Kubernetes repos.
- It contains about 4.6M records as of Feb 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L1046-L1073).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L726-L735).
- This table is updated every hour via [util_sql/postprocess_texts.sql](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_texts.sql).
- It is called by [this code](https://github.com/cncf/devstats/blob/master/structure.go#L1162-L1187) that uses [gha_postprocess_scripts](https://github.com/cncf/devstats/blob/master/docs/tables/gha_postprocess_scripts.md) table to get postprocess scripts to run. One of them, defined above creates entries for `gha_texts` table every hour.
- It adds all new comments, commit messages, issue titles, issue texts, PR titles, PR texts since last hour.
- See documentation for [issues](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues.md), [PRs](https://github.com/cncf/devstats/blob/master/docs/tables/gha_pull_requests.md) and [commits](https://github.com/cncf/devstats/blob/master/docs/tables/gha_commits.md) tables.
- This SQL script is scheduled to run every hour by: [util_sql/default_postprocess_scripts.sql](https://github.com/cncf/devstats/blob/master/util_sql/default_postprocess_scripts.sql#L1).
- Default postprocess scripts are defined by [kubernetes/setup_scripts.sh](https://github.com/cncf/devstats/blob/master/kubernetes/setup_scripts.sh#L4). This is `{{projectname}}/setup_scripts.sh` for other projects.
- Setup scripts is called by main Postgres init script, for kubernetes it is: [kubernetes/psql.sh](https://github.com/cncf/devstats/blob/master/kubernetes/psql.sh#L14).
- This is a part of standard when adding new project, for adding new project please see: [adding new project](https://github.com/cncf/devstats/blob/master/ADDING_NEW_PROJECT.md).
- When adding a project to an existing database that contains merge result from multiple projects, you need to manually remove eventual duplicates using: [./devel/remove_db_dups.sh](https://github.com/cncf/devstats/blob/master/devel/remove_db_dups.sh), as suggested by [cmd/merge_pdbs/merge_pdbs.go](https://github.com/cncf/devstats/blob/master/cmd/merge_pdbs/merge_pdbs.go#L197).
- Informations about creating project that is a merge of other multiple projects can be found in [adding new project](https://github.com/cncf/devstats/blob/master/ADDING_NEW_PROJECT.md).
- Its primary key isn't `event_id`, because it adds both title and body of issues and commits.

# Columns

- `event_id`: GitHub event ID. This ID is artificially generated for pre-2015 events.
- `body`: text, can be very long.
- `created_at`: date of the corresponding GitHub event.
- `actor_id`: actor ID responsible for this text. Refers to [gha_actors](https://github.com/cncf/devstats/blob/master/docs/tables/gha_actors.md) table.
- `actor_login`: actor GitHub login responsible for this text. Refers to [gha_actors](https://github.com/cncf/devstats/blob/master/docs/tables/gha_actors.md) table.
- `repo_id`: GitHub repository ID where this text was added. Refers to [gha_repos](https://github.com/cncf/devstats/blob/master/docs/tables/gha_repos.md) table.
- `repo_name`: GitHub repository name where this text was added. please not that repository names can change in time, but ID remains the same.
- `type`: GitHub event type, can be: PullRequestReviewCommentEvent, MemberEvent, PushEvent, ReleaseEvent, CreateEvent, GollumEvent, TeamAddEvent, DeleteEvent, PublicEvent, ForkEvent, PullRequestEvent, IssuesEvent, WatchEvent, IssueCommentEvent, CommitCommentEvent.
### [docs/tables/gha_issues_pull_requests](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues_pull_requests.md)
# `gha_issues_pull_requests` table

- This is a compute table, that contains data to connect issues with PRs.
- It contains issue ID, PR ID and shared number (PR & Issue).
- It contains duplicated columns to allow queries on this single table instead of joins.
- It needs postprocessing that is defined in a standard project's setup script. It is updated in postprocess every hour.
- Setup scripts is called by main Postgres init script, for Kubernetes it is: [kubernetes/psql.sh](https://github.com/cncf/devstats/blob/master/kubernetes/psql.sh#L14)).
- It runs [kubernetes/setup_scripts.sh](https://github.com/cncf/devstats/blob/master/kubernetes/setup_scripts.sh#L4). This is `{{projectname}}/setup_scripts.sh` for other projects.
- SQL script [util_sql/postprocess_issues_prs.sql](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_issues_prs.sql) is scheduled to run every hour by: [util_sql/default_postprocess_scripts.sql](https://github.com/cncf/devstats/blob/master/util_sql/default_postprocess_scripts.sql#L3).
- It is called by [this code](https://github.com/cncf/devstats/blob/master/structure.go#L1162-L1187) that uses [gha_postprocess_scripts](https://github.com/cncf/devstats/blob/master/docs/tables/gha_postprocess_scripts.md) table to get postprocess scripts to run. One of them, defined above creates entries for `gha_issues_events_labels` table every hour.
- It contains about 69k records as of Mar 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L1135-L1149).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L375-L382).
- It has no primary kay, it only connects Issues with PRs.
- It contains data from [issues](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues.md), [PRs](https://github.com/cncf/devstats/blob/master/docs/tables/gha_pull_requests.md) tables.
- When adding a project to an existing database that contains merge result from multiple projects, you need to manually remove eventual duplicates using: [./devel/remove_db_dups.sh](https://github.com/cncf/devstats/blob/master/devel/remove_db_dups.sh), as suggested by [cmd/merge_pdbs/merge_pdbs.go](https://github.com/cncf/devstats/blob/master/cmd/merge_pdbs/merge_pdbs.go#L197).

# Columns

- `issue_id`: GitHub issue ID. See [gha_issues](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues.md) table.
- `pull_request_id`: GitHub Pull Request ID. See [gha_pull_requests](https://github.com/cncf/devstats/blob/master/docs/tables/gha_pull_requests.md) table.
- `number`: This is both Issue and PRs number. You can use #number in GitHub to refer to PR/Issue.
- `repo_id`: GitHub repository ID (from [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md)).
- `repo_name`: GitHub repository name (note that repository name can change in time, while repository ID cannot).
- `created_at`: Event creation date, comes from [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md).
### [docs/tables/gha_issues](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues.md)
# `gha_issues` table

- This is a table that holds GitHub issue state at a given point in time (`event_id` refers to [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md)).
- This is a variable table, for details check [variable table](https://github.com/cncf/devstats/blob/master/docs/tables/variable_table.md).
- [ghaapi2db](https://github.com/cncf/devstats/tree/master/cmd/ghapi2db/ghapi2db.go) tool is creating new issue state entries (artificial) when it detects that some issue/PR has wrong labels set or wrong milestone.
- It happens when somebody changes label and/or milestone without commenting on the issue, or after commenting. Change label/milestone is not creating any GitHub event, so the final issue/PR state can be wrong.
- It contains about 1.2M records but only 115K distinct issue IDs (Mar 2018 state) - this means that there are about 10 events per issue on average.
- Its primary key is `(event_id, id)`.
- There is a special [compute table](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues_pull_requests.md) that connects Issues with PRs.

# Columns

Most important columns are:
- `id`: GitHub Issue ID.
- `event_id`: GitHub event ID, see [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md).
- `body`: issue text.
- `created_at`: Issue creation date.
- `closed_at`: Issue close date. Note that this table holds Issue state in time, so for some event this date will be null, for some other it will be set. If issue was closed/opened multiple times - all historical close dates will be stored here.
- `milestone_id`: Milestone ID, see [gha_milestones](https://github.com/cncf/devstats/blob/master/docs/tables/gha_milestones.md).
- `number`: Issue number - this is an unique number within single repository.
- `state`: `open` or `closed` at given GitHub event `event_id` date.
- `title`: Issue title.
- `user_id`: GitHub user ID performing action on the issue.
- `assignee_id`: Assigned GitHub user, can be null.
- `is_pull_request`: true - this is a PR, false - this is an Issue. PRs are stored on this table too, but they have an additional record in [gha_pull_requests](https://github.com/cncf/devstats/blob/master/docs/tables/gha_pull_requests.md).
### [docs/tables/gha_skip_commits](https://github.com/cncf/devstats/blob/master/docs/tables/gha_skip_commits.md)
# `gha_skip_commits` table

- Table is used to store invalid SHAs, to skip processing them again.
- This is a const table, values are inserted once and doesn't change, see [const table](https://github.com/cncf/devstats/blob/master/docs/tables/const_table.md).
- We're listing all yet unprocessed commits using [util_sql/list_unprocessed_commits.sql](https://github.com/cncf/devstats/blob/master/util_sql/list_unprocessed_commits.sql) [here](https://github.com/cncf/devstats/blob/master/cmd/get_repos/get_repos.go#L468-L495).
- More details about commits processing [here](https://github.com/cncf/devstats/blob/master/docs/tables/gha_commits_files.md).
- Some commits are merge commits (skipped) or have no files modifed, or only refer to files that are marked to skip, or cannot be found etc. Their SHAs are put in this table. This is a part of commits sync that happens every hour.
- Files that are skipped are defined per project with `files_skip_pattern`, see yaml definition [here](https://github.com/cncf/devstats/blob/master/gha.go#L26).
- For Kubernetes it is defined [here](https://github.com/cncf/devstats/blob/master/projects.yaml#L13). Exclude regexp is `(^|/)_?(vendor|Godeps|_workspace)/` - it tries to exclude any work done on external packages. 
- To see code that excludes commit files, search for `filesSkipPattern` [mostly here](https://github.com/cncf/devstats/blob/master/cmd/get_repos/get_repos.go#L405) and [here](https://github.com/cncf/devstats/blob/master/cmd/get_repos/get_repos.go#L527-L537).
- If commit has no files after filtering excluded ones, its SHA is added to `gha_skip_commits` table.
- This is a special table, not created by any GitHub archive (GHA) event.
- It contains about 264K records as of Feb 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L1000-L1009).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L681-L683).
- Its primary key is `sha`.

# Columns

- `sha`: commit SHA.
- `dt`: date when this commit was marked as skipped.
### [docs/tables/gha_comments](https://github.com/cncf/devstats/blob/master/docs/tables/gha_comments.md)
# `gha_comments` table

- This is a table that holds GitHub comments state at a given point in time (`event_id` refers to [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md)).
- It contains issue and PR comments, PR review comments and commit comments.
- This is a variable table, for details check [variable table](https://github.com/cncf/devstats/blob/master/docs/tables/variable_table.md).
- It contains about 138K records (Mar 2018 state). There is usually only one event/comment. In rare cases we have review comments on an exiting comment.
- Its primary key is `(event_id, id)`.

# Columns

Most important columns are:
- `id`: GitHub Comment ID.
- `event_id`: GitHub event ID, see [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md).
- `body`: Comment text.
- `created_at`: Comment creation date.
- `updated_at`: Comment update date. Note that this table holds Comment state in time, comment can be modified, so updated_at will change.
- `user_id`: GitHub user ID who added comment.
- `commit_id`: If this is a commit comment, this contains commit SHA, see [gha_commits](https://github.com/cncf/devstats/blob/master/docs/tables/gha_commits.md).
- `position`: Position in file, can be null.
- `path`: File path if this is a commit comment, can be null.
### [docs/tables/gha_labels](https://github.com/cncf/devstats/blob/master/docs/tables/gha_labels.md)
# `gha_labels` table

- This table holds GitHub labels.
- This is a const table, values are inserted once and doesn't change, see [const table](https://github.com/cncf/devstats/blob/master/docs/tables/const_table.md).
- Labels are created during standard GitHub archives import from JSON [here](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L1277-L1282).
- In pre-2015 events labels [have no ID](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L1272).
- For any label found in JSON payload we're searching for existing label using name & color. If label is not found, it receives [artificial negative ID](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L282), see [here](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L263-L285).
- It contains about 2.6k records as of Mar 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L515-L531).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L391-L396).
- Its primary key is `(id)`.
- Values from this table are sometimes duplicated in other tables (to speedup processing) as `dup_label_name`, `dup_label_id` or `label_id`.

# Columns

- `id`: GitHub label ID.
- `name`: GitHub label name.
- `color`: Color as 6 hex digits: RRGGBB, R,G,B from {0, 1, 2, .., 9, a, b, c, d, f}.
- `is_default`: Not used, can be null. True - label is default, False/null - label is not default.
### [docs/tables/gha_payloads](https://github.com/cncf/devstats/blob/master/docs/tables/gha_payloads.md)
# `gha_payloads` table

- This is the main GHA (GitHub archives), every GitHub event contain payload. This event ID is this table's primary key `event_id`.
- This table serves to connect various payload structures for different event types - like connect Issue with Comment for Issue Comment event etc.
- This is a const table, values are inserted once and doesn't change, see [const table](https://github.com/cncf/devstats/blob/master/docs/tables/const_table.md).
- Payloads are created during standard GitHub archives import from JSON [here (pre-2015 format)](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L839) or [here (current format)](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L1105).
- Old (pre-20150 GitHub events have no ID, it is generated artificially [here](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L1355), old format ID are < 0.
- It contains about 1.8M records as of Feb 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L188-L236).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L504-L529).
- [ghaapi2db](https://github.com/cncf/devstats/tree/master/cmd/ghapi2db/ghapi2db.go) tool is creating events of type `ArtificialEvent` when it detects that some issue/PR has wrong labels set or wrong milestone.
- It happens when somebody changes label and/or milestone without commenting on the issue, or after commenting. Change label/milestone is not creating any GitHub event, so the final issue/PR state can be wrong.
- Artificial event's payloads are created too.
- Its primary key is GitHub event ID `event_id`.
- Each payload have single (1:1) entry in [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md) table.

# Columns

Most important columns are (most of them are only filled for a specific event type, so most can be null - with the exception of `event_id` and those starting with `dup_` which are copied from [gha_actors](https://github.com/cncf/devstats/blob/master/docs/tables/gha_actors.md), [gha_repos](https://github.com/cncf/devstats/blob/master/docs/tables/gha_repos.md) and [gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md)):
- `event_id`: GitHub event ID.
- `dup_type`: GitHub event type, can be: PullRequestReviewCommentEvent, MemberEvent, PushEvent, ReleaseEvent, CreateEvent, GollumEvent, TeamAddEvent, DeleteEvent, PublicEvent, ForkEvent, PullRequestEvent, IssuesEvent, WatchEvent, IssueCommentEvent, CommitCommentEvent.
- `head`: HEAD branch SHA.
- `action`: Action type, defined for some event types, can be null or `created`, `published`, `labeled`, `closed`, `opened`, `started`, `reopened`, `added`.
- `issue_id`: Issue ID (for Issue related events), see [gha_issues](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues.md).
- `pull_request_id`: Pull Request ID (for PR related events), see [gha_pull_requests](https://github.com/cncf/devstats/blob/master/docs/tables/gha_pull_requests.md).
- `comment_id`: Comment ID (for comment related events), see [gha_comments](https://github.com/cncf/devstats/blob/master/docs/tables/gha_comments.md).
- `number`: Issue number (only for Issues related event types) this is an unique number within single repository.
- `forkee_id`: Forkee ID (not used in any dashbord yet, so no docs yet) - `gha_forkee` table, see [structure.go](https://github.com/cncf/devstats/blob/master/structure.go).
- `release_id`: Release ID (not used in any dashbord yet, so no docs yet) - `gha_releases` table, see [structure.go](https://github.com/cncf/devstats/blob/master/structure.go).
- `commit`: Commit's SHA, see [gha_commits](https://github.com/cncf/devstats/blob/master/docs/tables/gha_commits.md).
- `dup_actor_id`: GitHub actor ID (actor who created this event).
- `dup_actor_login`: Duplicated GitHub actor login (from [gha_actors](https://github.com/cncf/devstats/blob/master/docs/tables/gha_actors.md) table).
- `dup_repo_id`: GitHub repository ID.
- `dup_repo_name`: Duplicated GitHub repository name (note that repository name can change in time, but repository ID remains the same, see [gha_repos](https://github.com/cncf/devstats/blob/master/docs/tables/gha_repos.md) table).
- `dup_created_at`: Event creation date.
### [docs/tables/gha_actors](https://github.com/cncf/devstats/blob/master/docs/tables/gha_actors.md)
# `gha_actors` table

- This table holds all GitHub actors (actor can be contributor, forker, commenter etc.)
- This is a const table, values are inserted once and doesn't change, see [const table](https://github.com/cncf/devstats/blob/master/docs/tables/const_table.md).
- Actors are created during standard GitHub archives import from JSON [here](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L20-L31).
- Actors imported from GHA have no name (only id and login), name can be updated by import affiliations tool.
- They can also be added by import affiliation tool [here](https://github.com/cncf/devstats/blob/master/cmd/import_affs/import_affs.go#L101-L108) or updated [here](https://github.com/cncf/devstats/blob/master/cmd/import_affs/import_affs.go#L199-L201).
- It contains about 77K records as of Feb 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L60-L76).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L41-L45).
- Its primary key is `id`.
- Values from this table are often duplicated in other tables (to speedup processing) as `dup_actor_id`, `dup_actor_login`.

# Columns

- `id`: actor ID, if > 0 then it comes from GitHub, if < 0 - created artificially (pre-2015 GitHub actors had no ID).
- `login`: actor's GitHub login (you can access profile via `https://github.com/login`).
- `name`: actors name, there is no `name` defined in GitHub archives JSONs, if this value is set - it means it was updated by the affiliations import tool (or entire actor entry comes from affiliations import tool).
### [docs/tables/gha_commits_files](https://github.com/cncf/devstats/blob/master/docs/tables/gha_commits_files.md)
# `gha_commits_files` table

- This table holds commit's files (added, removed, modified etc.)
- We're listing all yet unprocessed commits using [util_sql/list_unprocessed_commits.sql](https://github.com/cncf/devstats/blob/master/util_sql/list_unprocessed_commits.sql) [here](https://github.com/cncf/devstats/blob/master/cmd/get_repos/get_repos.go#L468-L495).
- Commit's files are created by `git` datasource using [git_files.sh](https://github.com/cncf/devstats/blob/master/git/git_files.sh) [here](https://github.com/cncf/devstats/blob/master/cmd/get_repos/get_repos.go#L356-L441).
- This generates data for this table.
- Some commits has no files modifed, they're marked as `skip commits` and their SHAs are put in `gha_skip_commits` table, info [here](https://github.com/cncf/devstats/blob/master/docs/tables/gha_skip_commits.md).
- It adds new commit's files every hour by running [get_repos tool](https://github.com/cncf/devstats/blob/master/cmd/get_repos/get_repos.go).
- This is a special table, not created by any GitHub archive (GHA) event. Its purpose is to hold all commits' files.
- This is a const table, values are inserted once and doesn't change, see [const table](https://github.com/cncf/devstats/blob/master/docs/tables/const_table.md).
- It contains about 534K records as of Feb 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L965-L978).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L180-L185).
- Its primary key is `(sha, path)`.

# Columns

- `sha`: commit SHA.
- `path`: file path, it doesn't include repo name, so can be something like `dir/file.ext`.
- `size`: file size at commit's date.
- `dt`: commit's date.
### [docs/tables/gha_events_commits_files](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events_commits_files.md)
# `gha_events_commits_files` table

- This table holds commit's files connected with GitHub event additional data.
- It uses `gha_skip_commits` table, info [here](https://github.com/cncf/devstats/blob/master/docs/tables/gha_skip_commits.md) as an input.
- Events commits files are generated using [util_sql/create_events_commits.sql](https://github.com/cncf/devstats/blob/master/util_sql/create_events_commits.sql) [here](https://github.com/cncf/devstats/blob/master/cmd/get_repos/get_repos.go#L566-L592).
- It adds new event's commit's files every hour, creating full files paths that include repository name.
- It needs postprocessing that is defined in a standard project's setup script. It is updated in postprocess every hour.
- Setup scripts is called by main Postgres init script, for Kubernetes it is: [kubernetes/psql.sh](https://github.com/cncf/devstats/blob/master/kubernetes/psql.sh#L14)).
- It runs [kubernetes/setup_scripts.sh](https://github.com/cncf/devstats/blob/master/kubernetes/setup_scripts.sh#L6-L8). This is `{{projectname}}/setup_scripts.sh` for other projects.
- SQL script [util_sql/postprocess_repo_groups.sql](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_repo_groups.sql) is scheduled to run every hour by: [util_sql/repo_groups_postprocess_script.sql](https://github.com/cncf/devstats/blob/master/util_sql/repo_groups_postprocess_script.sql).
- SQL script [util_sql/postprocess_repo_groups_from_repos.sql](https://github.com/cncf/devstats/blob/master/util_sql/postprocess_repo_groups_from_repos.sql) is scheduled to run every hour by: [util_sql/repo_groups_postprocess_script_from_repos.sql](https://github.com/cncf/devstats/blob/master/util_sql/repo_groups_postprocess_script_from_repos.sql).
- Those scripts first try to update commit event file's repository group first using file level granularity (1st script) and then fall back to repo level granularity (2nd script).
- They are called by [this code](https://github.com/cncf/devstats/blob/master/structure.go#L1162-L1187) that uses [gha_postprocess_scripts](https://github.com/cncf/devstats/blob/master/docs/tables/gha_postprocess_scripts.md) table to get postprocess scripts to run. One of them, defined above creates entries for `gha_issues_events_labels` table every hour.
- This is a special table, not created by any GitHub archive (GHA) event. Its purpose is to hold all commits' files connected with events data.
- It contains about 1.2M records as of Feb 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L979-L998).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L225-L235).
- Its primary key is `(sha, event_id, path)`.

# Columns

- `sha`: commit SHA.
- `event_id`: GitHub event ID that refers to this commit file.
- `path`: full path generated as repo's path (like org/repo) and file's path (like dir/file.ext) --> `org/repo/dir/file.ext`.
- `size`: file size at commit's date.
- `dt`: commit's date.
- `repo_group`: repository group - this is updated every hour based on commit's file's repository's repo group and (possibly for Kubernetes) file level granularity repository groups definitions, see [repo groups](https://github.com/cncf/devstats/blob/master/docs/repository_groups.md).
- `dup_repo_id`:  GitHub repository ID of given commit's file
- `dup_repo_name`: GitHub repository name, please note that repo name can change in time, but repo ID remains the same. Full path can contain historical repo names.
- `dup_type`: GitHub event type, can be: PullRequestReviewCommentEvent, MemberEvent, PushEvent, ReleaseEvent, CreateEvent, GollumEvent, TeamAddEvent, DeleteEvent, PublicEvent, ForkEvent, PullRequestEvent, IssuesEvent, WatchEvent, IssueCommentEvent, CommitCommentEvent.
- `dup_created_at`: GitHub event's creation date.
- Columns starting with `dup_` are copied from `gha_events` table entry, info [here](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md).
### [docs/tables/gha_events](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md)
# `gha_events` table

- This is the main GHA (GitHub archives) table. It represents single event.
- Each GHA JSON contains single GitHub event, and singe GHA hour archive file and a bunch (about 80k) JSONS (events) that happened this hour (I mean events on all GitHup repos, not only Kubernetes).
- This table holds all GitHub events. Other tables defined as [variable](https://github.com/cncf/devstats/blob/master/docs/tables/variable_table.md) have `event_id` as a part of their primary key.
- This is a const table, values are inserted once and doesn't change, see [const table](https://github.com/cncf/devstats/blob/master/docs/tables/const_table.md).
- Events are created during standard GitHub archives import from JSON [here (pre-2015 format)](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L791-L809) or [here (current format)](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L1056-L1074).
- Old (pre-20150 GitHub events have no ID, it is generated artificially [here](https://github.com/cncf/devstats/blob/master/cmd/gha2db/gha2db.go#L1355), old format ID are < 0.
- For details about pre-2015 and current format check [analysis](https://github.com/cncf/devstats/tree/master/analysis), per-2015 data is prefixed with `old_`, current format is prefixed with `new_`. Example old and new JSONs [here](https://github.com/cncf/devstats/tree/master/jsons).
- It contains about 1.8M records as of Feb 2018.
- It is created here: [structure.go](https://github.com/cncf/devstats/blob/master/structure.go#L23-L40).
- You can see its SQL structure here: [structure.sql](https://github.com/cncf/devstats/blob/master/structure.sql#L205-L216).
- Its primary key is `id`.
- Values from this table are often duplicated in other tables (to speedup processing) as `dup_type`, `dup_created_at`.
- [ghaapi2db](https://github.com/cncf/devstats/tree/master/cmd/ghapi2db/ghapi2db.go) tool is creating events of type `ArtificialEvent` when it detects that some issue/PR has wrong labels set or wrong milestone.
- It happens when somebody changes label and/or milestone without commenting on the issue, or after commenting. Change label/milestone is not creating any GitHub event, so the final issue/PR state can be wrong.
- Each GitHub event have single (1:1) entry in [gha_payloads](https://github.com/cncf/devstats/blob/master/docs/tables/gha_payloads.md) table.

# Columns

- `id`: GitHub event ID.
- `type`: GitHub event type, can be: PullRequestReviewCommentEvent, MemberEvent, PushEvent, ReleaseEvent, CreateEvent, GollumEvent, TeamAddEvent, DeleteEvent, PublicEvent, ForkEvent, PullRequestEvent, IssuesEvent, WatchEvent, IssueCommentEvent, CommitCommentEvent.
- `actor_id`: GitHub actor ID (actor who created this event).
- `repo_id`: GitHub repository ID.
- `public`: Is this event public? Always `true` because private events are not gathered by GHA (GitHub Archives).
- `created_at`: Event creation date.
- `org_id`: GitHub organization ID. Can be null.
- `forkee_id`: This is a old repository ID (for per-2015 events, for current format it is null).
- `dup_actor_login`: Duplicated GitHub actor login (from [gha_actors](https://github.com/cncf/devstats/blob/master/docs/tables/gha_actors.md) table).
- `dup_repo_name`: Duplicated GitHub repository name (note that repository name can change in time, but repository ID remains the same, see [gha_repos](https://github.com/cncf/devstats/blob/master/docs/tables/gha_repos.md) table).
### [docs/tables/variable_table](https://github.com/cncf/devstats/blob/master/docs/tables/variable_table.md)
# Variable table

- Data in those tables can change between GitHub events, and `event_id` is a part of this tables primary key.
- They represent different state of a given object at the time of a given GitHub event `event_id`.
- For example PRs/Issues can change labels, be closed/merged/reopened, repositories can have different numbers of stars, forks, watchers etc.
### [docs/dashboards/kubernetes/sig_mentions_labels_devel](https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions_labels_devel.md)
# SIG mentions using labels dashboard

Links:
- Postgres SQL files: [labels_sig_kind.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_sig_kind.sql), [labels_kind.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_kind.sql) and [labels_sig.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_sig.sql).
- InfluxDB series definition: [metrics.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml). Search for `labels_sig_kind`, `labels_sig` and `labels_kind`.
- Grafana dashboard JSON: [sig_mentions_using_labels.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_using_labels.json).
- User documentation: [sig_mentions_labels.md](https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions_labels.md).
- Production version: [view](https://k8s.devstats.cncf.io/d/42/sig-mentions-using-labels?orgId=1).
- Test version: [view](https://k8s.cncftest.io/d/42/sig-mentions-using-labels?orgId=1).

# Description

- We're quering `gha_issues_labels` and `gha_issues` tables.  Those tables contains issues and their labels.
- For more information about `gha_issues_labels` table please check: [docs/tables/gha_issues_labels.md](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues_labels.md).
- For more information about `gha_issues` table please check: [docs/tables/gha_issues.md](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues.md).
- We're counting distinct issues that contain specific labels for SIGs and categories/kinds.
- Issue belnogs to some `SIGNAME` SIG - when it has `sig/SIGNAME` label.
- Issue belongs to some `CAT` category/kind - when it has `kind/CAT` label.
- This dashboard shows stacked number of issues that belongs to given SIGs and categories/kinds (by using issue labels).
- First panel shows stacked chart of number of issues belonging to selected categories for a selected SIG. It stacks different categories/kinds. It uses first SQL.
- Second panel shows stacked chart of number of issues belonging to selected categories (no matter which SIG, even no SIG at all). It stacks different categories/kinds. It uses second SQL.
- Third panel shows stacked chart of number of issues belonging to a given SIGs. It stacks by SIG and displays all possible SIGs found. It uses third SQL.
- SIG list comes from values of `sig/SIG` labels, category list contains values of `kind/kind` labels.
- We're only looking for labels that have been created on the issue between `{{from}}` and `{{to}}` dates.
- Values for `from` and `to` will be replaced with final periods described later.
- Each row returns single value, so the metric type is: `multi_row_single_column`.
- First panel/first Postgres query: each row is in the format column 1: `sig_mentions_labels_sig_kind,SIG-kind`, column 2: `NumberOfSIGCategoryIssues`.
- Second panel/second Postgres query: each row is in the format column 1: `sig_mentions_labels_kind,kind`, column 2: `NumberOfCategoryIssues`.
- Thirs panel/third Postgres query: each row is in the format column 1: `sig_mentions_labels_sig,SIG`, column 2: `NumberOfSIGIssues`.
- All metrics use `multi_value: true`, so values are saved under different column name in a Influx DB series.

# Periods and Influx series

Metric usage is defined in metric.yaml as follows:
```
series_name_or_func: multi_row_single_column
sql: labels_sig
periods: d,w,m,q,y
aggregate: 1,7
skip: w7,m7,q7,y7
multi_value: true

(...)

series_name_or_func: multi_row_single_column
sql: labels_kind
periods: d,w,m,q,y
aggregate: 1,7
skip: w7,m7,q7,y7
multi_value: true

(...)

series_name_or_func: multi_row_single_column
sql: labels_sig_kind
periods: d,w,m,q,y
aggregate: 1,7
skip: w7,m7,q7,y7
multi_value: true
```
- It means that we should call Postgres metrics [labels_sig_kind.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_sig_kind.sql), [labels_kind.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_kind.sql) and [labels_sig.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_sig.sql).
- We should expect multiple rows each with 2 columns: 1st defines output Influx series name, 2nd defines value.
- See [here](https://github.com/cncf/devstats/blob/master/docs/periods.md) for periods definitions.
- The final InfluxDB series name would be: `sig_mentions_labels_sig_kind_[[period]]` or `sig_mentions_labels_kind_[[period]]` or `sig_mentions_labels_sig_[[period]]`. Where `[[period]]` will be from d,w,m,q,y,d7.
- First panel: each of those series (for example `sig_mentions_labels_sig_kind_q`) will contain multiple columns (each column represent single SIG-category) with quarterly time series data.
- Second panel: each of those series (for example `sig_mentions_labels_kind_w`) will contain multiple columns (each column represent single category) with weekly time series data.
- Third panel: each of those series (for example `sig_mentions_labels_sig_d7`) will contain multiple columns (each column represent single SIG) with moving average 7 days time series data.
- Final querys is here: [sig_mentions_using_labels.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_using_labels.json):
  - First panel: `SELECT /^[[sig]]-[[kinds]]$/ FROM \"sig_mentions_labels_sig_kind_[[period]]\" WHERE $timeFilter`.
  - Second panel: `SELECT /^[[kinds]]$/ FROM \"sig_mentions_labels_kind_[[period]]\" WHERE $timeFilter`.
  - Third panel: `SELECT * FROM \"sig_mentions_labels_sig_[[period]]\" WHERE $timeFilter`.
  - Third panel: We're selecting all columns, because we can only select single SIG from drop down, and there is no sense to show only one SIG on this panel.
- `$timeFiler` value comes from Grafana date range selector. It is handled by Grafana internally.
- `[[period]]` comes from Variable definition in dashboard JSON: [sig_mentions_using_labels.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_using_labels.json). Search for `"period"`.
- `[[sig]]` comes from Variable definition in dashboard JSON: [sig_mentions_using_labels.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_using_labels.json). Search for `"sig"`. You have to select exactly one SIG, it is used on the first panel.
- `[[kinds]]` comes from Variable definition in dashboard JSON: [sig_mentions_using_labels.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_using_labels.json). Search for `"kinds"`.
- Note that `[[kinds]]` is a multi value select and reqexp part `/^[[kinds]]$/` means that we want to see all values currently selected from the drop-down. `/^[[sig]]-[[kinds]]$/` will select all currently selected categories values for a selected SIG.
- SIGs come from the InfluxDB tags: `SHOW TAG VALUES WITH KEY = sig_mentions_labels_name`, this tag is defined here: [idb_tags.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/idb_tags.yaml#L52).
- Categories come from the InfluxDB tags: `SHOW TAG VALUES WITH KEY = sig_mentions_labels_kind_name`, this tag is defined here: [idb_tags.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/idb_tags.yaml#L56).
- For more informations about tags check [here](https://github.com/cncf/devstats/blob/master/docs/tags.md).
- Releases comes from Grafana annotations: [sig_mentions_using_labels.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_using_labels.json). Search for `"annotations"`.
- For more details about annotations check [here](https://github.com/cncf/devstats/blob/master/docs/annotations.md).
- Project name is customized per project, it uses `[[full_name]]` template variable [definition](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_using_labels.json). Search for `full_name`.
- Per project variables are defined using `idb_vars`, `pdb_vars` tools, more info [here](https://github.com/cncf/devstats/blob/master/docs/vars.md).
### [docs/dashboards/kubernetes/sig_mentions](https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions.md)
<h1 id="kubernetes-sig-mentions-dashboard">Kubernetes SIG mentions dashboard</h1>
<p>Links:</p>
<ul>
<li>Postgres <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/sig_mentions.sql" target="_blank">SQL file</a>.</li>
<li>InfluxDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml#L246-L252" target="_blank">series definition</a>.</li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions.json" target="_blank">JSON</a>.</li>
<li>Developer <a href="https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions_devel.md" target="_blank">documentation</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows stacked number of various SIG mentions.</li>
<li>We are getting SIG from all <strong>texts</strong>.</li>
<li>To find a SIG we&#39;re looking for texts like this <code>@kubernetes/sig-SIG-kind</code>, where kind can be: <em>bug, feature-request, pr-review, api-review, misc, proposal, design-proposal, test-failure</em>.</li>
<li>For example <code>@kubernetes/sig-cluster-lifecycle-pr-review</code> will evaluate to <code>cluster-lifecycle</code>.</li>
<li>Kind part is optional, so <code>@kubernetes/sig-node</code> will evaluate to <code>node</code>.</li>
<li>There can be other texts before and after the SIG, so <code>Hi there @kubernetes/sig-apps-feature-request, I want to ...</code> will evaluate to <code>apps</code>.</li>
<li>For exact <code>regexp</code> used, please check developer <a href="https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions_devel.md" target="_blank">documentation</a>.</li>
<li><strong>Texts</strong> means comments, commit messages, issue titles, issue texts, PR titles, PR texts, PR review texts.</li>
<li>You can filter by period and SIG(s).</li>
<li>Selecting period (for example week) means that dahsboard will count SIG mentions in these periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
<li>This dashboard allows to select multiple SIG, it contains special &#39;All&#39; value to display all SIGs.</li>
<li>We&#39;re also excluding bots activity, see <a href="https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md" target="_blank">excluding bots</a>.</li>
</ul>

### [docs/dashboards/kubernetes/reviewers](https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/reviewers.md)
<h1 id="kubernetes-reviewers-dashboard">Kubernetes reviewers dashboard</h1>
<p>Links:</p>
<ul>
<li>Metric <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/reviewers.sql" target="_blank">SQL file</a>.</li>
<li>InfluxDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml#L157-L162" target="_blank">series definition</a>.</li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json" target="_blank">JSON</a>.</li>
<li>Developer <a href="https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/reviewers_devel.md" target="_blank">documentation</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows the number of reviewers for a selected repository group or for all repository groups combined.</li>
<li>Reviewers is defined as someone who added pull request review comment(s) or added <code>/lgtm</code> or <code>/approve</code> text or added <code>lgtm</code> or <code>approve</code> label.</li>
<li>You can filter by repository group and period.</li>
<li>Selecting period (for example week) means that dahsboard will count distinct users who made a review in these periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/repository_groups.md" target="_blank">here</a> for more informations about repository groups.</li>
<li>We are skipping bots when calculating number of reviewers, see <a href="https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md" target="_blank">excluding bots</a> for details.</li>
</ul>

### [docs/dashboards/kubernetes/sig_mentions_labels](https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions_labels.md)
<h1 id="kubernetes-sig-mentions-labels-dashboard">Kubernetes SIG mentions using labels dashboard</h1>
<p>Links:</p>
<ul>
<li>First panel Postgres <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_sig_kind.sql" target="_blank">SQL file</a>.</li>
<li>Second panel Postgres <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_kind.sql" target="_blank">SQL file</a>.</li>
<li>Third panel Postgres <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_sig.sql" target="_blank">SQL file</a>.</li>
<li>InfluxDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml" target="_blank">series definition</a>. Search for <code>labels_sig_kind</code>, <code>labels_sig</code> and <code>labels_kind</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_using_labels.json" target="_blank">JSON</a>.</li>
<li>Developer <a href="https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions_labels_devel.md" target="_blank">documentation</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows stacked number of issues that belongs to given SIGs and categories/kinds (by using issue labels)</li>
<li>First panel shows stacked chart of number of issues belonging to selected categories for a selected SIG. It stacks different categories/kinds. It uses first SQL.</li>
<li>Second panel shows stacked chart of number of issues belonging to selected categories (no matter which SIG, even no SIG at all). It stacks different categories/kinds. It uses second SQL.</li>
<li>Third panel shows stacked chart of number of issues belonging to a given SIGs. It stacks by SIG and displays all possible SIGs found. It uses third SQL.</li>
<li>To mark issue as belonging to some <code>SIGNAME</code> SIG - it must have <code>sig/SIGNAME</code> label.</li>
<li>To mark issue as belonging to some <code>CAT</code> category/kind - it must have <code>kind/CAT</code> label.</li>
<li>SIG list comes from values of <code>sig/SIG</code> labels, category list contains values of <code>kind/kind</code> labels.</li>
<li>You can filter by SIG and categories.</li>
<li>You must select exactly one SIG.</li>
<li>You can select multiple categories to display, or select special value <em>All</em> to display all categories.</li>
<li>Selecting period (for example week) means that dahsboard will count issues in these periods. 7 Day MA will count issues in 7 day window and divide result by 7 (so it will be 7 days MA value)</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
</ul>

### [docs/dashboards/kubernetes/sig_mentions_cats](https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions_cats.md)
<h1 id="kubernetes-sig-mentions-categories-dashboard">Kubernetes SIG mentions categories dashboard</h1>
<p>Links:</p>
<ul>
<li>First panel Postgres <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/sig_mentions_cats.sql" target="_blank">SQL file</a>.</li>
<li>Second panel Postgres <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/sig_mentions_breakdown.sql" target="_blank">SQL file</a>.</li>
<li>InfluxDB <a href="https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml" target="_blank">series definition</a>. Search for <code>sig_mentions_cats</code> and <code>sig_mentions_breakdown</code></li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_categories.json" target="_blank">JSON</a>.</li>
<li>Developer <a href="https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions_cats_devel.md" target="_blank">documentation</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>This dashboard shows stacked number of various SIG categories mentions.</li>
<li>It shows stacked chart of each category mentions for all SIGs in one panel and stacked chart of each category mentions for a SIG selected from the drop down in another panel.</li>
<li>First panel uses first Postgres query, second panel uses second query.</li>
<li>There are following categories defined: <strong>bug, feature-request, pr-review, api-review, misc, proposal, design-proposal, test-failure</strong></li>
<li>We are getting SIG mentions from all <strong>texts</strong>.</li>
<li>To find a SIG we&#39;re looking for texts like this <code>@kubernetes/sig-SIG-category</code>.</li>
<li>For example <code>@kubernetes/sig-cluster-lifecycle-pr-review</code> will evaluate SIG to <code>cluster-lifecycle</code> and category to <code>pr-review</code>.</li>
<li>There can be other texts before and after the SIG, so <code>Hi there @kubernetes/sig-apps-feature-request, I want to ...</code> will evaluate to SIG: <code>apps</code>, category: <code>feature-request</code>.</li>
<li>For exact <code>regexp</code> used, please check developer <a href="https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions_cats_devel.md" target="_blank">documentation</a>.</li>
<li><strong>Texts</strong> means comments, commit messages, issue titles, issue texts, PR titles, PR texts, PR review texts.</li>
<li>You can filter by SIG and categories. You must select one SIG to display its categories stacked on the second panel. First panel aggregates category data for all SIGs.</li>
<li>You can select multiple categories to display, or select special value <em>All</em> to display all categories.</li>
<li>Selecting period (for example week) means that dahsboard will count SIG mentions in these periods.</li>
<li>See <a href="https://github.com/cncf/devstats/blob/master/docs/periods.md" target="_blank">here</a> for more informations about periods.</li>
<li>We&#39;re also excluding bots activity, see <a href="https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md" target="_blank">excluding bots</a>.</li>
</ul>

### [docs/dashboards/kubernetes/sig_mentions_cats_devel](https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions_cats_devel.md)
# SIG mentions categories dashboard

Links:
- Postgres SQL files: [sig_mentions_cats.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/sig_mentions_cats.sql) and [sig_mentions_breakdown.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/sig_mentions_breakdown.sql).
- InfluxDB series definition: [metrics.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml). Search for `sig_mentions_cats` and `sig_mentions_breakdown`.
- Grafana dashboard JSON: [sig_mentions_categories.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_categories.json).
- User documentation: [sig_mentions_cats.md](https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions_cats.md).
- Production version: [view](https://k8s.devstats.cncf.io/d/40/sig-mentions-categories?orgId=1).
- Test version: [view](https://k8s.cncftest.io/d/40/sig-mentions-categories?orgId=1).

# Description

- We're quering `gha_texts` table. It contains all 'texts' from all Kubernetes repositories.
- For more information about `gha_texts` table please check: [docs/tables/gha_texts.md](https://github.com/cncf/devstats/blob/master/docs/tables/gha_texts.md).
- We're counting distinct GitHub events (text related events: issue/PR/commit comments, PR reviews, issue/PR body texts, titles) that contain any SIG reference.
- On first panel we're groupping by category using first Postgres SQL.
- On second panel we're groupping SIG and category using second Postgres SQL.
- Regexp to match category is: `(?i)(?:^|\s)+(?:@kubernetes/sig-[\w\d-]+)(-bug|-feature-request|-pr-review|-api-review|-misc|-proposal|-design-proposal|-test-failure)s?(?:$|[^\w\d-]+)`.
- Regexp to match SIG and category is: `(?i)(?:^|\s)+((?:@kubernetes/sig-[\w\d-]+)(?:-bug|-feature-request|-pr-review|-api-review|-misc|-proposal|-design-proposal|-test-failure))s?(?:$|[^\w\d-]+)`.
- Example sig mentions: `@kubernetes/sig-node-bug`, `@Kubernetes/sig-apps-proposal`.
- We're only looking for texts created between `{{from}}` and `{{to}}` dates. Values for `from` and `to` will be replaced with final periods described later.
- We're also excluding bots activity (see [excluding bots](https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md))
- Each row returns single value, so the metric type is: `multi_row_single_column`.
- First panel/first Postgres query: each row is in the format column 1: `sig_mentions_texts_cat,CatName`, column 2: `NumberOfCategoryMentions`.
- Second panel/second Postgres query: each row is in the format column 1: `sig_mentions_texts_bd,SIGName-CatName`, column 2: `NumberOfSIGCategoryMentions`.
- Both metrics use `multi_value: true`, so values are saved under different column name in a Influx DB series.

# Periods and Influx series

Metric usage is defined in metric.yaml as follows:
```
series_name_or_func: multi_row_single_column
sql: sig_mentions_cats
periods: d,w,m,q,y
aggregate: 1,7
skip: w7,m7,q7,y7
multi_value: true

(...)

series_name_or_func: multi_row_single_column
sql: sig_mentions_breakdown
periods: d,w,m,q,y
aggregate: 1,7
skip: w7,m7,q7,y7
multi_value: true
```
- It means that we should call Postgres metrics [sig_mentions_cats.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/sig_mentions_cats.sql) or [sig_mentions_breakdown.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/sig_mentions_breakdown.sql).
- We should expect multiple rows each with 2 columns: 1st defines output Influx series name, 2nd defines value.
- See [here](https://github.com/cncf/devstats/blob/master/docs/periods.md) for periods definitions.
- The final InfluxDB series name would be: `sig_mentions_texts_cat_[[period]]` or `sig_mentions_texts_bd_[[period]]`. Where `[[period]]` will be from d,w,m,q,y,d7.
- First panel: each of those series (for example `sig_mentions_texts_cat_d7`) will contain multiple columns (each column represent single category) with time series data.
- Second panel: each of those series (for example `sig_mentions_texts_bd_d7`) will contain multiple columns (each column represent single SIG-category) with time series data.
- Final querys is here: [sig_mentions_categories.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_categories.json):
  - First panel: `SELECT /^[[sigcats]]$/ FROM \"sig_mentions_texts_cat_[[period]]\" WHERE $timeFilter`.
  - Second panel: `SELECT /^[[sig]]-[[sigcats]]$/ FROM \"sig_mentions_texts_bd_[[period]]\" WHERE $timeFilter`.
- `$timeFiler` value comes from Grafana date range selector. It is handled by Grafana internally.
- `[[period]]` comes from Variable definition in dashboard JSON: [sig_mentions_categories.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_categories.json). Search for `"period"`.
- `[[sig]]` comes from Variable definition in dashboard JSON: [sig_mentions_categories.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_categories.json). Search for `"sig"`. You have to select exactly one SIG, it is used on the second panel.
- `[[sigcats]]` comes from Variable definition in dashboard JSON: [sig_mentions_categories.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_categories.json). Search for `"sigcats"`.
- Note that `[[sigcats]]` is a multi value select and reqexp part `/^[[sigcats]]$/` means that we want to see all values currently selected from the drop-down. `/^[[sig]]-[[sigcats]]$/` will select all currently selected categories values for a selected SIG.
- SIGs come from the InfluxDB tags: `SHOW TAG VALUES WITH KEY = sig_mentions_texts_name`, this tag is defined here: [idb_tags.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/idb_tags.yaml#L44).
- Categories come from the InfluxDB tags: `SHOW TAG VALUES WITH KEY = sig_mentions_texts_cat_name`, this tag is defined here: [idb_tags.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/idb_tags.yaml#L48).
- For more informations about tags check [here](https://github.com/cncf/devstats/blob/master/docs/tags.md).
- Releases comes from Grafana annotations: [sig_mentions_categories.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_categories.json). Search for `"annotations"`.
- For more details about annotations check [here](https://github.com/cncf/devstats/blob/master/docs/annotations.md).
- Project name is customized per project, it uses `[[full_name]]` template variable [definition](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_categories.json). Search for `full_name`.
- Per project variables are defined using `idb_vars`, `pdb_vars` tools, more info [here](https://github.com/cncf/devstats/blob/master/docs/vars.md).
### [docs/dashboards/kubernetes/reviewers_devel](https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/reviewers_devel.md)
# Kubernetes reviewers dashboard

Links:
- Postgres SQL file: [reviewers.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/reviewers.sql).
- InfluxDB series definition: [metrics.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml#L157-L162).
- Grafana dashboard JSON: [reviewers.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json).
- User documentation: [reviewers.md](https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/reviewers.md).
- Production version: [view](https://k8s.devstats.cncf.io/d/38/reviewers?orgId=1).
- Test version: [view](https://k8s.cncftest.io/d/38/reviewers?orgId=1).

# Description

- We're quering `gha_texts` table. It contains all 'texts' from all Kubernetes repositories.
- For more information about `gha_texts` table please check: [docs/tables/gha_texts.md](https://github.com/cncf/devstats/blob/master/docs/tables/gha_texts.md).
- We're creating temporary table 'matching' which contains all event IDs that contain `/lgtm` or `/approve` (no case sensitive) in a separate line (there can be more lines before and/or after this line).
- The exact psql regexp is: `(?i)(?:^|\n|\r)\s*/(?:lgtm|approve)\s*(?:\n|\r|$)`.
- We're only looking for texts created between `{{from}}` and `{{to}}` dates. Values for `from` and `to` will be replaced with final periods described later.
- Then we're creating 'reviews' temporary table that contains all event IDs (`gha_events`) that belong to GitHub event type: `PullRequestReviewCommentEvent`.
- For more information about `gha_events` table please check: [docs/tables/gha_event.md](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md).
- Then comes the final select which returns multiple rows (one for All repository groups combined and then one for each repository group).
- Each row returns single value, so the metric type is: `multi_row_single_column`.
- Each row is in the format column 1: `reviewers,RepoGroupName`, column 2: `NumberOfReviewersInThisRepoGroup`. Number of rows is N+1, where N=number of repo groups. One additional row for `reviewers,All` that contains number of repo groups for all repo groups.
- Value for each repository group is calculated as a number of distinct actor logins who:
- Are not bots (see [excluding bots](https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md))
- Added `lgtm` or `approve` label in a given period (`gha_issues_events_labels` table)
- For more information about `gha_issues_events_labels` table please check: [docs/tables/gha_issues_events_labels.md](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues_events_labels.md).
- Added text matching given regexp.
- Added PR review comment (event type `PullRequestReviewCommentEvent`).
- Event belong to a given repository group (in repo group part of the SQL, this is not checked for 'All' repo group that conatins data from all repository groups).
- Finally temp tables are dropped.
- For repository group definition check: [repository groups](https://github.com/cncf/devstats/blob/master/docs/repository_groups.md) (table `gha_events` and commit files for file level granularity repo groups).
- For more information about `gha_repos` table please check: [docs/tables/gha_repos.md](https://github.com/cncf/devstats/blob/master/docs/tables/gha_repos.md).

# Periods and Influx series

Metric usage is defined in metric.yaml as follows:
```
series_name_or_func: multi_row_single_column
sql: reviewers
periods: d,w,m,q,y
aggregate: 1,7
skip: w7,m7,q7,y7
```
- It means that we should call Postgres metric [reviewers.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/reviewers.sql).
- We should expect multiple rows each with 2 columns: 1st defines output Influx series name, 2nd defines value.
- See [here](https://github.com/cncf/devstats/blob/master/docs/periods.md) for periods definitions.
- The final InfluxDB series name would be: `reviewers_[[repogroup]]_[[period]]`. Where [[period]] will be from d,w,m,q,y,d7 and [[repogroup]] will be from 'all,apps,contrib,kubernetes,...', see [repository groups](https://github.com/cncf/devstats/blob/master/docs/repository_groups.md) for details.
- Repo group name returned by Postgres SQL is normalized (downcased, removed special chars etc.) to be usable as a Influx series name [here](https://github.com/cncf/devstats/blob/master/cmd/db2influx/db2influx.go#L112) using [this](https://github.com/cncf/devstats/blob/master/unicode.go#L23).
- Final query is here: [reviewers.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json#L116): `SELECT "value" FROM "autogen"."reviewers_[[repogroup]]_[[period]]" WHERE $timeFilter`.
- `$timeFiler` value comes from Grafana date range selector. It is handled by Grafana internally.
- `[[period]]` comes from Variable definition in dashboard JSON: [reviewers.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json#L188-L234).
- `[[repogroup]]` comes from Grafana variable that uses influx tags values: [reviewers.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json#L236-L274).
- You are selecting `repogroup_name` from Grafana UI (this drop-down is visible), values are: All,Apps,Cluster lifecycle, ...
- Then Grafana uses `repogroup` which is a hidden variable that normalizes this name using other tag value that matches `repogroup_name`.
- To see more details about repository group tags, and all other tags check [tags.md](https://github.com/cncf/devstats/blob/master/docs/tags.md).
- Releases comes from Grafana annotations: [reviewers.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json#L43-L55).
- For more details about annotations check [here](https://github.com/cncf/devstats/blob/master/docs/annotations.md).
- Project name is customized per project, it uses `[[full_name]]` template variable [definition](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json#L275-L293) and is [used as project name](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json#L78).
- Per project variables are defined using `idb_vars`, `pdb_vars` tools, more info [here](https://github.com/cncf/devstats/blob/master/docs/vars.md).
### [docs/dashboards/kubernetes/sig_mentions_devel](https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions_devel.md)
# SIG mentions dashboard

Links:
- Postgres SQL file: [sig_mentions.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/sig_mentions.sql).
- InfluxDB series definition: [metrics.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml#L246-L252).
- Grafana dashboard JSON: [sig_mentions.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions.json).
- User documentation: [sig_mentions.md](https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions.md).
- Production version: [view](https://k8s.devstats.cncf.io/d/41/sig-mentions?orgId=1).
- Test version: [view](https://k8s.cncftest.io/d/41/sig-mentions?orgId=1).

# Description

- We're quering `gha_texts` table. It contains all 'texts' from all Kubernetes repositories.
- For more information about `gha_texts` table please check: [docs/tables/gha_texts.md](https://github.com/cncf/devstats/blob/master/docs/tables/gha_texts.md).
- We're counting distinct GitHub events (text related events: issue/PR/commit comments, PR reviews, issue/PR body texts, titles) that contain any SIG reference.
- We're groupping this by SIG.
- Regexp to match SIG is: `(?i)(?:^|\s)+(@kubernetes/sig-[\w\d-]+)(?:-bug|-feature-request|-pr-review|-api-review|-misc|-proposal|-design-proposal|-test-failure)s?(?:$|[^\w\d-]+)` with `(?i)(?:^|\s)+(@kubernetes/sig-[\w\d-]*[\w\d]+)(?:$|[^\w\d-]+)` fallback.
- Example sig mentions: `@kubernetes/sig-node-bug`, `@Kubernetes/sig-apps`.
- We're only looking for texts created between `{{from}}` and `{{to}}` dates. Values for `from` and `to` will be replaced with final periods described later.
- We're also excluding bots activity (see [excluding bots](https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md))
- Each row returns single value, so the metric type is: `multi_row_single_column`.
- Each row is in the format column 1: `sig_mentions_texts,SIGName`, column 2: `NumberOfSIGMentions`.
- This metric uses `multi_value: true`, so each SIG is saved under different column name in a Influx DB series.

# Periods and Influx series

Metric usage is defined in metric.yaml as follows:
```
series_name_or_func: multi_row_single_column
sql: sig_mentions
periods: d,w,m,q,y
aggregate: 1,7
skip: w7,m7,q7,y7
multi_value: true
```
- It means that we should call Postgres metric [sig_mentions.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/sig_mentions.sql).
- We should expect multiple rows each with 2 columns: 1st defines output Influx series name, 2nd defines value.
- See [here](https://github.com/cncf/devstats/blob/master/docs/periods.md) for periods definitions.
- The final InfluxDB series name would be: `sig_mentions_texts_[[period]]`. Where `[[period]]` will be from d,w,m,q,y,d7.
- Each of those series (for example `sig_mentions_texts_d7`) will contain multiple columns (each column represent single SIG) with time series data.
- Final query is here: [sig_mentions.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions.json#L117): `SELECT /^[[sigs]]$/ FROM \"sig_mentions_texts_[[period]]\" WHERE $timeFilter`.
- `$timeFiler` value comes from Grafana date range selector. It is handled by Grafana internally.
- `[[period]]` comes from Variable definition in dashboard JSON: [sig_mentions.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions.json#L184-L225).
- `[[sigs]]` comes from Variable definition in dashboard JSON: [sig_mentions.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions.json#L230-L248).
- Note that this is a multi value select and reqexp part `/^[[sigs]]$/` means that we want to see all values currently selected from the drop-down.
- SIGs come from the InfluxDB tags: `SHOW TAG VALUES WITH KEY = sig_mentions_texts_name`, this tag is defined here: [idb_tags.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/idb_tags.yaml#L44).
- For more informations about tags check [here](https://github.com/cncf/devstats/blob/master/docs/tags.md).
- Releases comes from Grafana annotations: [sig_mentions.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions.json#L43-L55).
- For more details about annotations check [here](https://github.com/cncf/devstats/blob/master/docs/annotations.md).
- Project name is customized per project, it uses `[[full_name]]` template variable [definition](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions.json#L251-L268) and is [used as project name](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions.json#L54).
- Per project variables are defined using `idb_vars`, `pdb_vars` tools, more info [here](https://github.com/cncf/devstats/blob/master/docs/vars.md).
### [docs/dashboards/dashboards_devel](https://github.com/cncf/devstats/blob/master/docs/dashboards/dashboards_devel.md)
# Home dashboard

Links:
- Postgres SQL file: [events.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/events.sql).
- InfluxDB series definition: [metrics.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml#L319-L322).
- Grafana dashboard JSON: [dashboards.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json).
- User documentation: [dashboards.md](https://github.com/cncf/devstats/blob/master/docs/dashboards/dashboards.md).
- Production version: [view](https://k8s.devstats.cncf.io/d/12/dashboards?refresh=15m&orgId=1).
- Test version: [view](https://k8s.cncftest.io/d/12/dashboards?refresh=15m&orgId=1).

# Description

- First we're displaying links to all CNCF projects defined. Links are defined [here](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json#L91-L270).
- Next we're showing current project's hourly activity:
  - We're quering `gha_events` table to get the total number of GitHub events.
  - For more information about `gha_events` table please check: [gha_events.md](https://github.com/cncf/devstats/blob/master/docs/tables/gha_events.md).
  - We're summing events hourly.
  - This is a small project activity chart, we're not excluding bots activity here (most other dashboards excludes bot activity).
  - Each row returns single value, we're only groupoing hourly here, so InfluxDB series name is given directly [here](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml#L319-L322) as `events_h`.
- Next we're showing HTML panel that shows all CNCF projects icons and links. Its contents comes from Postgres `[[projects]]` variable
- Next there is a dashboard that shows a list of all dashboards defined for the current project (Kubernetes in this case).
- Next we're showing dashboard docuemntaion. Its contents comes from Postgres `[[docs]]` variable

# Influx series

Metric usage is defined in metric.yaml as follows:
```
series_name_or_func: events_h
sql: events
periods: h
```
- It means that we should call Postgres metric [events.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/events.sql).
- We will save to InfluxDB series name `events_h`, query returns just single value for a given hour.
- Grafana query is here: [dashboards.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json#L324): `SELECT \"value\" FROM \"events_h\" WHERE $timeFilter`.
- `$timeFiler` value comes from Grafana date range selector. It is handled by Grafana internally.
- This InfluxDB series is always calculated [last](https://github.com/cncf/devstats/blob/master/context.go#L222), and it is [queried](https://github.com/cncf/devstats/blob/master/cmd/gha2db_sync/gha2db_sync.go#L314) to see last hour calculated when doing a hourly sync.
- Releases comes from Grafana annotations: [dashboards.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json#L69-L82).
- For more details about annotations check [here](https://github.com/cncf/devstats/blob/master/docs/annotations.md).
- Project name is customized per project, it uses `[[full_name]]` template variable [definition](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json#L528-L547) and is [used as project name](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json#L344).
- Dashboard's CNCF projects list with icons and links comes from `[[projects]]` Postgres template variable defined [here](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json#L468-#L487).
- Its definition is [here](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/pdb_vars.yaml#L9-L15).
- It uses this [HTML partial](https://github.com/cncf/devstats/blob/master/partials/projects.html) replacing `[[hostname]]` with then current host name.
- Dashboard's documentation comes from `[[docs]]` Postgres template variable defined [here](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json#L488-#L507).
- Its definition is [here](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/pdb_vars.yaml#L16-L25).
- It uses this [HTML](https://github.com/cncf/devstats/blob/master/docs/dashboards/dashboards.md) replacing `[[hostname]]` with then current host name and `[[full_name]]` with Kubernetes.
- It also replaces `[[proj_name]]` with contents of environment variable `GHA2DB_PROJECT`, using `$GHA2DB_PROJECT` syntax.
- It also replaces `[[url_prefix]]` with direct string `k8s`, using syntax `:k8s`.
- Per project variables are defined using `idb_vars`, `pdb_vars` tools, more info [here](https://github.com/cncf/devstats/blob/master/docs/vars.md).
### [docs/dashboards/dashboards](https://github.com/cncf/devstats/blob/master/docs/dashboards/dashboards.md)
<h1 id="-full_name-home-dashboard">[[full_name]] Home dashboard</h1>
<p>Links:</p>
<ul>
<li>Postgres <a href="https://github.com/cncf/devstats/blob/master/metrics/[[proj_name]]/events.sql" target="_blank">SQL file</a>.</li>
<li>InfluxDB <a href="https://github.com/cncf/devstats/blob/master/metrics/[[proj_name]]/metrics.yaml" target="_blank">series definition</a> (search for <code>name: GitHub activity</code>).</li>
<li>Grafana dashboard <a href="https://github.com/cncf/devstats/blob/master/grafana/dashboards/[[proj_name]]/dashboards.json" target="_blank">JSON</a>.</li>
<li>Developer <a href="https://github.com/cncf/devstats/blob/master/docs/dashboards/dashboards_devel.md" target="_blank">documentation</a>.</li>
<li>Direct <a href="https://[[url_prefix]].[[hostname]]" target="_blank">link</a>.</li>
</ul>
<h1 id="description">Description</h1>
<ul>
<li>First we&#39;re displaying links to all CNCF projects defined.</li>
<li>Next we&#39;re showing current project&#39;s hourly activity - this is the number of all GitHub events that happened for [[full_name]] project hourly.</li>
<li>This also includes bots activity (most other dashboards skip bot activity).</li>
<li>Next we&#39;re showing HTML panel that shows all CNCF projects icons and links.</li>
<li>Next there is a dashboard that shows a list of all dashboards defined for [[full_name]] project.</li>
</ul>

### [docs/periods](https://github.com/cncf/devstats/blob/master/docs/periods.md)
# DevStats metrics periods definitions

- Periods can be: h,d,w,m,q,y which means we should calculate this SQL for every hour, day, week, month, quarter and year since start of a given project.
- That means about 34K+ hour ranges, 1400+ days, 210 weeks, 48 months, 12 quarter, 4 years (for Kubernetes project example as of Mar 2018).
- `{{from}}` and `{{to}}` will be replaced with those daily, weekly, .., yearly ranges.
- Aggregate (any positive integer) for example 1,7 means that we should calculate moving averages for 1 and 7.
- Aggregate 1 means nothing - just calculate value.
- Aggregate 7 means that we should calculate d7, w7, m7, q7 and y7 periods. d7 means that we're calculate period with 7 days length, but iterating 1 day each time. For example 1-8 May, then 2-9 May, then 3-10 May and so on.
- Skip: w7, m7, q7, y7 means that we should exclude those periods, so we will only have d7 left. That means we're calculating d,w,m,q,y,d7 periods. d7 is very useful, becasue it contains all 7 week days (so values are similar) but we're progressing one day instead of 7 days.
- d7 = '7 Days MA' = '7 days moving average'.
- h24 = '24 Hours MA' = '24 hours moving avegage'.
- Note that moving averages can give non-intuitive values, for example let's say there were 10 issues in 7 days. 7 Days MA will give you value 10/7 = 1.42857... which doesnt look like a correct Issue number. But this means avg 1.49 issue/day in 7 Days moving average period.
### [docs/excluding_bots](https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md)
# Excluding bots

- You can put excluding bots partial `{{exclude_bots}}` anywhere in the metric SQL.
- You should put exclude bots partial inside parentheses like for example: `(actor_login {{exclude_bots}})`.
- `{{exclude_bots}}` will be replaced with the contents of the [util_sql/exclude_bots.sql](https://github.com/cncf/devstats/blob/master/util_sql/exclude_bots.sql).
- Currently is is defined as: `not like all(array['googlebot', 'coveralls', 'rktbot', 'coreosbot', 'web-flow', 'k8s-%', '%-bot', '%-robot', 'bot-%', 'robot-%', '%[bot]%', '%-jenkins', '%-ci%bot', '%-testing', 'codecov-%'])`.
- Most actor related metrics use this.
### [docs/github](https://github.com/cncf/devstats/blob/master/docs/github.md)
# GitHub (GHAPI) datasource details

- You need to have `/etc/github/oauth` file created on your server, this file should contain OAuth token.
- Without this file you are limited to 60 API calls, see [GitHub info](https://developer.github.com/v3/#rate-limiting).
- You can force using unauthorized acces by setting environment variable `GHA2DB_GITHUB_OAUTH` to `-` - this is not recommended.
### [DOCKER](https://github.com/cncf/devstats/blob/master/DOCKER.md)
# Install docker

Please note that I wa sunsble to run multiple Grafanas in separate docker instances.
I was invetingating this for a long time and the final state was that docker containers are not 100% good for this.

- sudo apt-get update
- sudo apt-get install apt-transport-https ca-certificates curl software-properties-common
- curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
- sudo apt-key fingerprint 0EBFCD88
- sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
- sudo apt-get update
- sudo apt-get install docker-ce

Docker can have problems with storage driver, you can select `aufs` storage option by doing:
- `modprobe aufs`
- `vim /etc/docker/daemon.json`, and put storage driver here:
```
{
          "storage-driver": "aufs"
} 
```
- If want to secure InfluxDB and use Docker at the same time please see: [SECURE_INFLUXDB.md](https://github.com/cncf/devstats/blob/master/SECURE_INFLUXDB.md).
### [INSTALL_UBUNTU17](https://github.com/cncf/devstats/blob/master/INSTALL_UBUNTU17.md)
# devstats installation on Ubuntu

Prerequisites:
- Ubuntu 17.04.
- [golang](https://golang.org), this tutorial uses Go 1.6
    - `apt-get update`
    - `apt-get install golang git psmisc jsonlint yamllint gcc`
    - `mkdir /data; mkdir /data/dev`
1. Configure Go:
    - For example add to `~/.bash_profile` and/or `~/.profile`:
     ```
     GOPATH=$HOME/data/dev; export GOPATH
     PATH=$PATH:$GOPATH/bin; export PATH
     ```
    - Logout and login again.
    - [golint](https://github.com/golang/lint): `go get -u github.com/golang/lint/golint`
    - [goimports](https://godoc.org/golang.org/x/tools/cmd/goimports): `go get golang.org/x/tools/cmd/goimports`
    - [goconst](https://github.com/jgautheron/goconst): `go get github.com/jgautheron/goconst/cmd/goconst`
    - [usedexports](https://github.com/jgautheron/usedexports): `go get github.com/jgautheron/usedexports`
    - [errcheck](https://github.com/kisielk/errcheck): `go get github.com/kisielk/errcheck`
    - Go InfluxDB client: install with: `go get github.com/influxdata/influxdb/client/v2`
    - Go Postgres client: install with: `go get github.com/lib/pq`
    - Go unicode text transform tools: install with: `go get golang.org/x/text/transform` and `go get golang.org/x/text/unicode/norm`
    - Go YAML parser library: install with: `go get gopkg.in/yaml.v2`
    - Go GitHub API client: `go get github.com/google/go-github/github`
    - Go OAuth2 client: `go get golang.org/x/oauth2`
2. Go to $GOPATH/src/ and clone devstats there:
    - `git clone https://github.com/cncf/devstats.git`, cd `devstats`
    - Set reuse TCP connections (Golang InfluxDB may need this under heavy load): `./scripts/net_tcp_config.sh`
    - This variable can be unavailable on your system, ignore the warining if this is the case.
3. If you want to make changes and PRs, please clone `devstats` from GitHub UI, and clone your forked version instead, like this:
    - `git clone https://github.com/your_github_username/devstats.git`
6. Go to devstats directory, so you are in `~/dev/go/src/devstats` directory and compile binaries:
    - `make`
7. If compiled sucessfully then execute test coverage that doesn't need databases:
    - `make test`
    - Tests should pass.
8. Install binaries & metrics:
    - `sudo mkdir /etc/gha2db`
    - `sudo chmod 777 /etc/gha2db`
    - `sudo make install`

9. Install Postgres database ([link](https://gist.github.com/sgnl/609557ebacd3378f3b72)):
    - apt-get install postgresql (you can use specific version, for example `postgresql-9.6`)
    - sudo -i -u postgres
    - psql
    - Postgres only allows local connections by default so it is secure, we don't need to disable external connections:
    - Config file is: `/etc/postgresql/9.6/main/pg_hba.conf`, instructions to enable external connections (not recommended): `http://www.thegeekstuff.com/2014/02/enable-remote-postgresql-connection/?utm_source=tuicool`

10. Inside psql client shell:
    - `create database gha;`
    - `create database devstats;`
    - `create user gha_admin with password 'your_password_here';`
    - `grant all privileges on database "gha" to gha_admin;`
    - `grant all privileges on database "devstats" to gha_admin;`
    - `alter user gha_admin createdb;`
    - Leave the shell and create logs table for devstats: `sudo -u postgres psql devstats < util_sql/devstats_log_table.sql`.

11. Leave `psql` shell, and get newest Kubernetes database dump:
    - `wget https://devstats.cncf.io/gha.dump`.
    - `sudo -u postgres pg_restore -d gha gha.dump` (restore DB dump)
    - Create `ro_user` via `PG_PASS=... ./devel/create_ro_user.sh`

12. Install InfluxDB time-series database ([link](https://docs.influxdata.com/influxdb/v0.9/introduction/installation/)):
    - Ubuntu 17 contains an old `influxdb` when installed by default `apt-get install influxdb`, so:
    - `curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -`
    - `source /etc/lsb-release`
    - `echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list`
    - `apt-get install apt-transport-https`
    - `sudo apt-get update && sudo apt-get install influxdb`
    - `sudo service influxdb start`
    - Create InfluxDB user, database: `IDB_HOST="localhost" IDB_PASS='your_password_here' IDB_PASS_RO='ro_user_password' ./grafana/influxdb_setup.sh gha`
    - InfluxDB has authentication disabled by default.
    - Edit config file `vim /usr/local/etc/influxdb.conf` and change section `[http]`: `auth-enabled = true`, `max-body-size = 0`, `[subscriber]`: `http-timeout = "300s"`, `write-concurrency = 96`, `[coordinator]`: `write-timeout = "60s"`.
    - If you want to disable external InfluxDB access (for any external IP, only localhost) follow those instructions [SECURE_INFLUXDB.md](https://github.com/cncf/devstats/blob/master/SECURE_INFLUXDB.md).
    - `sudo service influxdb restart`

13. Databases installed, you need to test if all works fine, use database test coverage:
    - `GHA2DB_PROJECT=kubernetes IDB_DB=dbtest IDB_HOST="localhost" IDB_PASS=your_influx_pwd PG_DB=dbtest PG_PASS=your_postgres_pwd make dbtest`
    - Tests should pass.

14. We have both databases running and Go tools installed, let's try to sync database dump from k8s.devstats.cncf.io manually:
    - We need to prefix call with GHA2DB_LOCAL to enable using tools from "./" directory
    - To import data for the first time (Influx database is empty and postgres database is at the state when Kubernetes SQL dump was made on [k8s.devstats.cncf.io](https://k8s.devstats.cncf.io)):
    - You need to have GitHub OAuth token, either put this token in `/etc/github/oauth` file or specify token value via GHA2DB_GITHUB_OAUTH=deadbeef654...10a0 (here you token value)
    - If you really don't want to use GitHub OAuth2 token, specify `GHA2DB_GITHUB_OAUTH=-` - this will force tokenless operation (via public API), it is a lot more rate limited than OAuth2 which gives 5000 API points/h
    - `IDB_HOST="localhost" IDB_PASS=pwd PG_PASS=pwd ./kubernetes/reinit_all.sh`
    - This can take a while (depending how old is psql dump `gha.sql.xz` on [k8s.devstats.cncf.io](https://k8s.devstats.cncf.io). It is generated daily at 3:00 AM UTC.
    - Command should be successfull.

15. We need to setup cron job that will call sync every hour (10 minutes after 1:00, 2:00, ...)
    - You need to open `crontab.entry` file, it looks like this for single project setup (this is obsolete, please use `devstats` mode instead):
    ```
    8 * * * * PATH=$PATH:/path/to/your/GOPATH/bin GHA2DB_CMDDEBUG=1 GHA2DB_PROJECT=kubernetes IDB_HOST="localhost" IDB_PASS='...' PG_PASS='...' gha2db_sync 2>> /tmp/gha2db_sync.err 1>> /tmp/gha2db_sync.log
    20 3 * * * PATH=$PATH:/path/to/your/GOPATH/bin cron_db_backup.sh gha 2>> /tmp/gha2db_backup.err 1>> /tmp/gha2db_backup.log
    */5 * * * * PATH=$PATH:/path/to/your/GOPATH/bin GOPATH=/your/gopath GHA2DB_CMDDEBUG=1 GHA2DB_PROJECT_ROOT=/path/to/repo PG_PASS="..." GHA2DB_SKIP_FULL_DEPLOY=1 webhook 2>> /tmp/gha2db_webhook.err 1>> /tmp/gha2db_webhook.log
    ```
    - For multiple projects you can use `devstats` instead of `gha2db_sync` and `cron/cron_db_backup_all.sh` instead of `cron/cron_db_backup.sh`.
    ```
    7 * * * * PATH=$PATH:/path/to/GOPATH/bin IDB_HOST="localhost" IDB_PASS="..." PG_PASS="..." devstats 2>> /tmp/gha2db_sync.err 1>> /tmp/gha2db_sync.log
    30 3 * * * PATH=$PATH:/path/to/GOPATH/bin cron_db_backup_all.sh 2>> /tmp/gha2db_backup.err 1>> /tmp/gha2db_backup.log
    */5 * * * * PATH=$PATH:/path/to/GOPATH/bin GOPATH=/go/path GHA2DB_CMDDEBUG=1 GHA2DB_PROJECT_ROOT=/path/to/repo GHA2DB_DEPLOY_BRANCHES="production,master" PG_PASS=... GHA2DB_SKIP_FULL_DEPLOY=1 webhook 2>> /tmp/gha2db_webhook.err 1>> /tmp/gha2db_webhook.log
    ```
    - First crontab entry is for automatic GHA sync.
    - Second crontab entry is for automatic daily backup of GHA database.
    - Third crontab entry is for Continuous Deployment - this a Travis Web Hook listener server, it deploys project when specific conditions are met, details [here](https://github.com/cncf/devstats/blob/master/CONTINUOUS_DEPLOYMENT.md).
    - You need to change "..." PG_PASS, IDB_HOST and IDB_PASS to the real postgres password value and copy this line.
    - You need to change "/path/to/your/GOPATH/bin" to the value of "$GOPATH/bin", you cannot use $GOPATH in crontab directly.
    - Run `crontab -e` and put this line at the end of file and save.
    - Cron job will update Postgres and InfluxDB databases at 0:10, 1:10, ... 23:10 every day.
    - It outputs logs to `/tmp/gha2db_sync.out` and `/tmp/gha2db_sync.err` and also to gha Postgres database: into table `gha_logs`.
    - Check database values and logs about 15 minutes after full hours, like 14:15:
    - Check max event created date: `select max(created_at) from gha_events` and logs `select * from gha_logs order by dt desc limit 20`.

16. Install [Grafana](http://docs.grafana.org/installation/mac/) or use Docker to enable multiple Grafana instances, see [MULTIPROJECT.md](https://github.com/cncf/devstats/blob/master/MULTIPROJECT.md).

    - `sudo apt-get install -y adduser libfontconfig`
    - `sudo dpkg -i grafana_4.5.2_amd64.deb`
    - `sudo service grafana-server start`
    - Configure Grafana, as described [here](https://github.com/cncf/devstats/blob/master/GRAFANA.md).
    - `service grafana-server restart`
    - Go to Grafana UI (localhost:3000), choose sign out, and then access localhost:3000 again. You should be able to view dashboards as a guest. To login again use http://localhost:3000/login.
    - Install Apache as described [here](https://github.com/cncf/devstats/blob/master/APACHE.md).
    - You can also enable SSL, to do so you need to follow SSL instruction in [SSL](https://github.com/cncf/devstats/blob/master/SSL.md) (that requires domain name).

17. To change all Grafana page titles (starting with "Grafana - ") and icons use this script:
    - `GRAFANA_DATA=/usr/share/grafana/ ./grafana/{{project}}/change_title_and_icons.sh`.
    - `GRAFANA_DATA` can also be `/usr/share/grafana.prometheus/` for example, see [MULTIPROJECT.md](https://github.com/cncf/devstats/blob/master/MULTIPROJECT.md).
    - Replace `GRAFANA_DATA` with your Grafana data directory.
    - `service grafana-server restart`
    - In some cases browser and/or Grafana cache old settings in this case temporarily move Grafana's `settings.js` file:
    - `mv /usr/share/grafana/public/app/core/settings.js /usr/share/grafana/public/app/core/settings.js.old`, restart grafana server and restore file.
    - On Safari you can use Develop -> Empty Caches followed by refresh page (Command+R).

18. To enable Continuous deployment using Travis, please follow instructions [here](https://github.com/cncf/devstats/blob/master/CONTINUOUS_DEPLOYMENT.md).

19. You can create new metrics (as SQL files and YAML definitions) and dashboards in Grafana (export as JSON).
20. PRs and suggestions are welcome, please create PRs and Issues on the [GitHub](https://github.com/cncf/devstats).

# More details
- [Local Development](https://github.com/cncf/devstats/blob/master/DEVELOPMENT.md).
- [README](https://github.com/cncf/devstats/blob/master/README.md)
- [USAGE](https://github.com/cncf/devstats/blob/master/USAGE.md)
### [ARCHITECTURE](https://github.com/cncf/devstats/blob/master/ARCHITECTURE.md)
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
- All GitHub events are packed into multi-json gzipped files each hour and made available from [Github Archive](https://www.githubarchive.org/). To use this data, you need to extract all hours (since the Kubernetes project started) and filter out all data except for events from the 4 kubernetes organizations ([kubernetes](https://github.com/kubernetes), [kubernetes-incubator](https://github.com/kubernetes-incubator), [kubernetes-client](https://github.com/kubernetes-client), [kubernetes-helm](https://github.com/kubernetes-helm)).
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

3) `db2influx` (computes metrics given as SQL files to be run on Postgres and saves time series output to InfluxDB)
- [db2influx](https://github.com/cncf/devstats/blob/master/cmd/db2influx/db2influx.go)
- This separates metrics complex logic in SQL files, `db2influx` executes parameterized SQL files and write final time-series to InfluxDB.
- Parameters are `'{{from}}'`, `'{{to}}'` to allow computing the given metric for any date period.
- For histogram metrics there is a single parameter `'{{period}}'` instead. To run `db2influx` in histogram mode add "h" as last parameter after all other params. `gha2db_sync` already handles this.
- This means that InfluxDB will only hold multiple time-series (very simple data). InfluxDB is extremely good at manipulating such kind of data - this is what it was created for.
- Grafana will read from InfluxDB by default and will use its power to generate all possible aggregates, minimums, maximums, averages, medians, percentiles, charts etc.
- Adding new metric will mean add Postgres SQL that will compute this metric.

4) `gha2db_sync` (synchronizes GitHub archive data and Postgres, InfluxDB databases)
- [gha2db_sync](https://github.com/cncf/devstats/blob/master/cmd/gha2db_sync/gha2db_sync.go)
- This program figures out what is the most recent data in Postgres database then queries GitHub archive from this date to current date.
- It will add data to Postgres database (since the last run)
- It will update summary tables and/or (materialized) views on Postgres DB.
- It will update new commits files list using `get_repos` program.
- Then it will call `db2influx` for all defined SQL metrics and update Influx database as well.
- You need to set `GHA2DB_PROJECT=project_name` currently it can be either kubernetes, prometheus or opentracing. Projects are defined in `projects.yaml` file.
- It reads a list of metrics from YAML file: `metrics/{{project}}/metrics.yaml`, some metrics require to fill gaps in their data. Those metrics are defined in another YAML file `metrics/{{project}}/gaps.yaml`. Please try to use Grafana's "nulls as zero" instead of using gaps filling.
- This tool also supports initial computing of All InfluxDB data (instead of default update since the last run).
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
- [z2influx](https://github.com/cncf/devstats/blob/master/cmd/z2influx/z2influx.go)
- `z2influx` is used to fill gaps that can occur for metrics that returns multiple columns and rows, but the number of rows depends on date range, it uses [gaps.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/gaps.yaml) file to define which metrics should be zero filled.
- Please use Grafana's "null as zero" instead of using manuall filling gaps. This simplifies metrics a lot.
- [annotations](https://github.com/cncf/devstats/blob/master/cmd/annotations/annotations.go)
- `annotations` is used to add annotations on charts. It uses GitHub API to fetch tags from project main repository defined in `projects.yaml`, it only includes tags matching annotation regexp also defined in `projects.yaml`.
- [idb_tags](https://github.com/cncf/devstats/blob/master/cmd/idb_tags/idb_tags.go)
- `idb_tags` is used to add InfluxDB tags on some specified series. Those tags are used to populate Grafana template drop-down values and names. This is used to auto-populate Repository groups drop down, so when somebody adds new repository group - it will automatically appear in the drop-down.
- `idb_tags` uses [idb_tags.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/idb_tags.yaml) file to configure InfluxDB tags generation.
- [idb_backup](https://github.com/cncf/devstats/blob/master/cmd/idb_backup/idb_backup.go)
- `idb_backup` is used to backup/restore InfluxDB. Full renenerate of InfluxDB takes about 12 minutes. To avoid downtime when we need to rebuild InfluDB - we can generate new InfluxDB on `test` database and then if succeeded, restore it on `gha`. Downtime will be about 2 minutes.
- You can use all defined environments variables, but add `_SRC` suffic for source database and `_DST` suffix for destination database.
- [webhook](https://github.com/cncf/devstats/blob/master/cmd/webhook/webhook.go)
- `webhook` is used to react to Travis CI webhooks and trigger deploy if status, branch and type match defined values, more details [here](https://github.com/cncf/devstats/blob/master/CONTINUOUS_DEPLOYMENT.md).
- Add `[no deploy]` to the commit message, to skip deploying.
- Add `[ci skip]` to skip testing (will not spawn Travis CI build).
- Add `[deploy]` to do a full deploy using `./devel/deploy_all.sh` script, this needs more environment variables to be set, see [here](https://github.com/cncf/devstats/blob/master/CONTINUOUS_DEPLOYMENT.md).
- There are few shell scripts for example: running sync every N seconds, setup InfluxDB etc.
- [merge_pdbs](https://github.com/cncf/devstats/blob/master/cmd/merge_pdbs/merge_pdbs.go)
- `merge_pdbs` is used to generate Postgres database that contains data from other multiple databases.
- You can use `merge_pdbs` to add new projects to a existing database, but please consider running './devel/remove_db_dups.sh' then or use: './all/add_project.sh' script.
- [replacer](https://github.com/cncf/devstats/blob/master/cmd/replacer/replacer.go)
- `replacer` is used to mass replace data in text files. It has regexp modes, string modes, terminate on no match etc.
- [idb_vars](https://github.com/cncf/devstats/blob/master/cmd/idb_vars/idb_vars.go)
- `idb_vars` is used to add special variables (tags) to Influx database, see [here](https://github.com/cncf/devstats/blob/master/docs/vars.md) for more info.
- [pdb_vars](https://github.com/cncf/devstats/blob/master/cmd/pdb_vars/pdb_vars.go)
- `pdb_vars` is used to add special variables (tags) to Influx database, see [here](https://github.com/cncf/devstats/blob/master/docs/vars.md) for more info.

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
