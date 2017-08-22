# GitHub Archives to PostgreSQL/MySQL

Author: Łukasz Gryglicki <lukaszgryglick@o2.pl>

This tools filters GitHub archive for given date period and given organization, repository and saves results in MySQL and/or Postgres database.
It can also save results into JSON files.
It displays results using Grafana and InfluxDB time series database.

Usage:

`ENV_VARIABLES ./gha2db.rb YYYY-MM-DD HH YYYY-MM-DD HH [org [repo]]`

First two parameters are date from:
- YYYY-MM-DD
- HH

Next two parameters are date to:
- YYYY-MM-DD
- HH

Both next two parameters are optional:
- org (if given and non empty '' then only return JSONs matching given org). You can also provide a comma separated list of orgs here: 'org1,org2,org3'.
- repo (if given and non empty '' then only return JSONs matching given repo). You can also provide a comma separated list of repos here: 'repo1,repo2'.

Org/Repo filtering:
- You can filter only by org by passing for example 'kubernetes' for org and '' for repo or skipping repo.
- You can filter only by repo, You need to pass '' as org and then repo name.
- You can return all JSONs by skipping both params.
- You can provide both to observe only events from given org/repo.

# Configuration

You can tweak `gha2db.rb` by:

- Set `GHA2DB_PSQL` to use PostgreSQL output.
- Set `GHA2DB_MYSQL` to use MySQL output.
- You need to set `GHA2DB_PSQL` or `GHA2DB_MYSQL` to use DB output.
- Set `GHA2DB_ST` environment variable to run single threaded version.
- Set `GHA2DB_JSON` to save single events JSONs in `jsons/` directory.
- Set `GHA2DB_NODB` to skip DB processing at all (if `GHA2DB_JSON` not set it will parse all data from GHA, but do nothing with it).
- Set `GHA2DB_DEBUG` set to 1 to see output for all events generated, set to 2 to see all SQL query parameters.
- Set `GHA2DB_QOUT` to see all SQL queries.

Examples in this shell script (some commented out, some not):

`time GHA2DB_PSQL=1 PG_PASS=your_pass ./gha2db.sh`

# Informations

GitHub archives keeps data as Gzipped JSONs for each hour (24 gzipped JSONs per day).
Single JSON is not a real JSON file, but "\n" newline separated list of JSONs for each GitHub event in that hour.
So this is a JSON array in reality.

GihHub archive files can be found there <https://www.githubarchive.org>

For example to fetch 2017-08-03 18:00 UTC can be fetched by:

`wget http://data.githubarchive.org/2017-08-03-18.json.gz`

Gzipped files are usually 10-30 Mb in size (single hour).
Decompressed fiels are usually 100-200 Mb.

We download this gzipped JSON, process it on the fly, creating array of JSON events and
then each single event JSON matching org/repo criteria is saved in `jsons` directory as
`N_ID.json` where:
- N - given GitHub archive''s JSON hour as UNIX timestamp.
- ID - GitHub event ID.

Once saved, You can review those JSONs manually (they're pretty printed).

# Mutithreading

For example <http://cncftest.io> server has 48 CPU cores.
It will just process 48 hours in parallel.
It detects number of available CPUs automatically.

# Results

# JSON:

Usually there are about 25000 GitHub events in single hour in Jan 2017 (for July 2017 it is 40000).
Average seems to be from 15000 to 60000.

1) Running this program on a 5 days of data with org `kubernetes` (and no repo set - which means all kubernetes repos):
- Takes: 10 minutes 50 seconds.
- Generates 12002 JSONs in `jsons/` directory with summary size 165 Mb (each JSON is a single GitHub event).
- To do so it processes about 21 Gb of data.
- XZipped file: `results/k8s_5days_jsons.tar.xz`.

2) Running this program 1 month of data with org `kubernetes` (and no repo set - which means all kubernetes repos).
June 2017:
- Takes: 61 minutes 26 seconds.
- Generates 60773 JSONs in `jsons/` directory with summary size 815 Mb.
- To do so it processes about 126 Gb of data.
- XZipped file: `results/k8s_month_jsons.tar.xz`.

3) Running this program 3 hours of data with no filters.
2017-07-05 hours: 18, 19, 20:
- Takes: 55 seconds.
- Generates 168683 JSONs in `jsons/` directory with summary size 1.1 Gb.
- To do so it processes about 126 Gb of data.
- XZipped file: `results/all_3hours_jsons.tar.xz`.

Taking all events from single day is 5 minutes 50 seconds (2017-07-28):
- Generates 1194599 JSON files (1.2M)
- Takes 7 Gb of disck space

# Databases:

# PostgreSQL:

1) Running on all 3 orgs `kubernetes,kubernetes-client,kubernetes-incubator` repos for June 2017 yields:
- Takes: 61 minutes 52 seconds.
- Note that those counts include historical changes to objects (for example single issue can have multiple entries with dirrent state on different events)
- Creates 5765 actors.
- Creates 42 assets.
- Creates 28552 branches.
- Creates 51412 comments.
- Creates 5989 commits.
- Creates 67911 events.
- Creates 5989 event - commit connections.
- Creates 32 event - page connections.
- Creates 29816 forkees.
- Creates 46328 issues.
- Creates 31078 issue - assignee connections.
- Creates 151478 issue - label connections.
- Creates 601 labels.
- Creates 15364 milestones.
- Creates 3 orgs.
- Creates 32 pages.
- Creates 67911 payloads.
- Creates 14280 pull requests.
- Creates 8140 pull request - assignee connections.
- Creates 3168 pull request - requested reviewer connections.
- Creates 50 releases.
- Creates 42 release - asset connections.
- Creates 70 repos.
- See `results/k8s_month_psql.sql.xz`

2) Running for 3 days 25th, 26th, 27th July 2017 (without org/repo filers) yields:
- Takes: 55 minutes 16 seconds.
- Note that those counts include historical changes to objects (for example single issue can have multiple entries with dirrent state on different events)
- Creates 614901 actors.
- Creates 10682 assets.
- Creates 616456 branches.
- Creates 391575 comments.
- Creates 3158733 commits.
- Creates 3826738 events.
- Creates 3158731 event - commit connections.
- Creates 21357 event - page connections.
- Creates 565224 forkees.
- Creates 439524 issues.
- Creates 16299 issue - assignee connections.
- Creates 261149 issue - label connections.
- Creates 48918 labels.
- Creates 47518 milestones.
- Creates 50894 orgs.
- Creates 22581 pages.
- Creates 3826726 payloads.
- Creates 308277 pull requests.
- Creates 5161 pull request - assignee connections.
- Creates 37140 pull request - requested reviewer connections.
- Creates 17992 releases.
- Creates 10682 release - asset connections.
- Creates 670613 repos.
- See <https://cncftest.io/web/all_3days_psql.sql.xz>

3) Running on 3 Kubernetes orgs for 2017-01-01 - 2017-08-01:
- Takes 7 hours 30 minutes.
- Generates 455321 events.

4) Finally running on all Kubernetes org since real beginning (2015-08-06 22:00 UTC) until (2017-08-02 14:00 UTC):
- Takes 11 hours 6 minutes (*really* 666 minutes)
- Database dump is 5.01 Gb, XZ compressed dump is 267 Mb
- Note that those counts include historical changes to objects (for example single issue can have multiple entries with dirrent state on different events)
- Creates 38470 actors.
- Creates 259 assets.
- Creates 484327 branches.
- Creates 882089 comments.
- Creates 91973 commits.
- Creates 1133757 events.
- Creates 91973 event - commit connections.
- Creates 777 event - page connections.
- Creates 499620 forkees.
- Creates 764744 issues.
- Creates 210208 issue - assignee connections.
- Creates 2321179 issue - label connections.
- Creates 1440 labels.
- Creates 189529 milestones.
- Creates 3 orgs.
- Creates 777 pages.
- Creates 1133757 payloads.
- Creates 242203 pull requests.
- Creates 67501 pull request - assignee connections.
- Creates 9757 pull request - requested reviewer connections.
- Creates 490 releases.
- Creates 259 release - asset connections.
- Creates 87 repos.
- See <https://cncftest.io/web/k8s_psql.sql.xz>

# MySQL
1) Running on all Kubernetes org since real beginning (2015-08-06 22:00 UTC) until (2017-08-18 06:00 UTC):
- Takes about 20 hours (MySQL is a lot slower than Postgres)
- Database dump is 5.17 Gb, XZ compressed dump is 249 Mb
- Note that those counts include historical changes to objects (for example single issue can have multiple entries with dirrent state on different events)
- Creates 39222 actors.
- Creates 262 assets.
- Creates 506629 branches.
- Creates 915225 comments.
- Creates 96166 commits.
- Creates 1178301 events.
- Creates 96166 event - commit connections.
- Creates 793 event - page connections.
- Creates 522872 forkees.
- Creates 792780 issues.
- Creates 230748 issue - assignee connections.
- Creates 2406121 issue - label connections.
- Creates 1488 labels.
- Creates 192904 milestones.
- Creates 3 orgs.
- Creates 793 pages.
- Creates 1178300 payloads.
- Creates 253357 pull requests.
- Creates 73876 pull request - assignee connections.
- Creates 11902 pull request - requested reviewer connections.
- Creates 510 releases.
- Creates 262 release - asset connections.
- Creates 90 repos.
- See <https://cncftest.io/web/k8s_mysql.sql.xz>

# PostgreSQL database
Setup:

Ubuntu like Linux:

- apt-get install postgresql 
- sudo -i -u postgres
- psql
- create database gha;
- create user gha_admin with password 'your_password_here';
- grant all privileges on database "gha" to gha_admin;
- GHA2DB_PSQL=1 PG_PASS='pwd' ./structure.rb
- psql gha

`structure.rb` script is used to create Postgres database schema.
It gets connection details from environmental variables and falls back to some defaults.

Defaults are:
- Database host: environment variable PG_HOST or `localhost`
- Database port: PG_PORT or 5432
- Database name: PG_DB or 'gha'
- Database user: PG_USER or 'gha_admin'
- Database password: PG_PASS || 'password'
- If You want it to generate database indexes set `GHA2DB_INDEX` environment variable
- If You want to skip table creations set `GHA2DB_SKIPTABLE` environment variable (when `GHA2DB_INDEX` also set, it will create indexes on already existing table structure, possibly already populated)
- If You want to skip creating DB tools (like views and functions), use `GHA2DB_SKIPTOOLS` environment variable.

Recommended run is to create structure without indexes first (the default), then get data from GHA and populate array, and finally add indexes. To do do:
- `time GHA2DB_PSQL=1 PG_PASS=your_password ./structure.rb`
- `time GHA2DB_PSQL=1 PG_PASS=your_password ./gha2db.sh`
- `time GHA2DB_PSQL=1 GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 PG_PASS=your_password ./structure.rb` (will take some time to generate indexes on populated database)

Typical internal usage:
`time GHA2DB_PSQL=1 GHA2DB_INDEX=1 PG_PASS=your_password ./structure.rb`

Alternatively You can use `structure_psql.sql` to create database structure.

# MySQL database

Ubuntu like Linux:

- sudo apt-get install mysql-server
- sudo mysql_secure_installation
- You will need `lib_mysqludf_pcre` to support PCRE REGEXPs (*)
- Update mysql config to use UTF8MB4, see below (**)
- mysql -uusername -ppassword
- create database gha character set utf8mb4 collate utf8mb4_unicode_ci;
- create user 'gha_admin'@'localhost' identified by 'your_password_here';
- grant all privileges on gha.* to 'gha_admin'@'localhost';
- flush privileges;
- GHA2DB_MYSQL=1 MYSQL_PASS='pwd' ./structure.rb
- mysql -uusername -ppassword gha

`structure.rb` script is used to create MySQL database schema.
It gets connection details from environmental variables and falls back to some defaults.

Defaults are:
- Database host: environment variable MYSQL_HOST or `localhost`
- Database port: MYSQL_PORT or 3306
- Database name: MYSQL_DB or 'gha'
- Database user: MYSQL_USER or 'gha_admin'
- Database password: MYSQL_PASS || 'password'
- If You want it to generate database indexes set `GHA2DB_INDEX` environment variable
- If You want to skip table creations set `GHA2DB_SKIPTABLE` environment variable (when `GHA2DB_INDEX` also set, it will create indexes on already existing table structure, possibly already populated)
- If You want to skip creating DB tools (like views and functions), use `GHA2DB_SKIPTOOLS` environment variable.

Recommended run is to create structure without indexes first (the default), then get data from GHA and populate array, and finally add indexes. To do do:
- `time GHA2DB_MYSQL=1 MYSQL_PASS=your_password ./structure.rb`
- `time GHA2DB_MYSQL=1 MYSQL_PASS=your_password ./gha2db.sh`
- `time GHA2DB_MYSQL=1 GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 MYSQL_PASS=your_password ./structure.rb` (will take some time to generate indexes on populated database)

Typical internal usage:
`time GHA2DB_MYSQL=1 GHA2DB_INDEX=1 MYSQL_PASS=your_password ./structure.rb`

Alternatively You can use `structure_mysql.sql` to create database structure.

(*) Install lib_mysqludf_pcre` (*)
You need this because MySQL has no native REGEXP extraction functions, and built in MySQL's `regexp` is terribly slow (and it can only return 0/1 for regexp matching).
- apt-get install libpcre3-dev
- git clone https://github.com/mysqludf/lib_mysqludf_preg.git
- cd lib_mysqludf_preg
- ./configure
- You may need to run `touch aclocal.m4 configure Makefile.*` before next step due to aclocal strange errors.
- make
- make install
- make MYSQL="mysql -p" installdb

(**) Update MySQL to use UTF8MB4:
This is needed because there are a lot of full UTF8 texts in GHA archives,a nd starndard MySQL's `utf8` is not fully compatible with UTF8 standard.
- Locate Your MySQL config file (usually in `/etc/mysql/my.cnf`
- Make sure You have those options:
```
[client]
default-character-set = utf8mb4

[mysql]
default-character-set = utf8mb4

[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
```
- Restart mysql service: `service mysql restart`
- See if You have correct variables: `show variables where Variable_name like 'character\_set\_%' or Variable_name like 'collation%';`
- For detailed description see <https://mathiasbynens.be/notes/mysql-utf8mb4>

# Database structure

You can see database structure in `structure.rb`, `structure_psql.sql`, `structure_mysql.sql`.

Main idea is that we divide tables into 2 groups:
- const: meaning that data in this table is not changing in time (is saved once)
- variable: meaning that data in those tables can change between GH events, and GH event_id is a part of this tables primary key.

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

# Adding columns to existing database

Postgres:
- alter table table_name add col_name col_def;
- update ...
- alter table table_name alter column col_name set not null;

MySQL:
- alter table table_name add col_name col_def;
- update ...
- alter table table_name modify col_name col_def not null;

# JSON structure analysis tool
There is also an internal tool: `analysis.rb`/`analysis.sh` to figure out how to create tables for gha.
But this is only useful while developing this tool.

This tool can generate all possible distinct structures of any key at any depth, to see possible veriants of this key.
It was used very intensively during development of SQL table structure.

# Running on Kubernetes

Kubernetes consists of 3 different orgs, so to gather data for Kubernetes You need to provide them comma separated.

For example June 2017:

`time GHA2DB_PSQL=1 PG_PASS=pwd ./gha2db.rb 2017-06-01 0 2017-07-01 0 'kubernetes,kubernetes-incubator,kubernetes-client'`

# Metrics tool
There is also a tool `runq.rb`. It is used to compute metrics saved in `sql` files.

Example metrics are in `./psql_metrics/` and `./mysql_metrics/` directories.
They're usually different for different databases (they're complex SQL's that uses DB specific REGEXP processing etc)

This tool takes single parameter - sql file name.

Typical usages:
- `time GHA2DB_PSQL=1 PG_PASS='password' ./runq.rb psql_metrics/metric.sql`
- `time GHA2DB_MYSQL=1 MYSQL_PASS='password' ./runq.rb mysql_metrics/metric.sql`

Some SQL files require parameter substitution (like all metrics used by Grafana).

They usually have `'{{from}}'` and `'{{to}}'` parameters, to run such files do:
`time GHA2DB_MYSQL=1 MYSQL_PASS='password' ./runq.rb mysql_metrics/metric.sql '{{from}}' 'YYYY-MM-DD HH:MM:SS' '{{to}}' 'YYYY-MM-DD HH:MM:SS'`

You can also change any other value, just note that parameters after SQL file name are pairs: `value_to_replace` `replacement`.

# Metrics results

For last GitHub archive date 2017-08-03 13:00 UTC:

1) SIG mentions (all of them takes <30 seconds, `time PG_PASS='pwd' ./runq.rb sql/sig_mentions_*.sql`):
- All Time:
```
time GHA2DB_PSQL=1 PG_PASS='pwd' ./runq.rb psql_metrics/sig_mentions_all_time.sql
/--------------------------+--------------\
|sig                       |count_all_time|
+--------------------------+--------------+
|sig-federation            |5006          |
|sig-apps                  |4793          |
|sig-api-machinery         |4554          |
|sig-node                  |3395          |
|sig-cli                   |3152          |
|sig-storage               |2469          |
|sig-scalability           |2453          |
|sig-scheduling            |2161          |
|sig-auth                  |1743          |
|sig-cluster-lifecycle     |1733          |
|sig-network               |1429          |
|sig-testing               |840           |
|sig-contributor-experience|480           |
|sig-release               |277           |
|sig-aws                   |76            |
|sig-instrumentation       |64            |
|sig-apimachinery          |49            |
|sig-autoscaling           |48            |
|sig-docs                  |30            |
|sig-openstack             |25            |
|sig-windows               |24            |
|sig-controller-manager    |21            |
|sig-OpenStack             |16            |
|sig-cluster-ops           |13            |
|sig-Apps                  |7             |
|sig-Auth                  |5             |
|sig-Network               |5             |
|sig-azure                 |4             |
|sig-rktnetes              |4             |
|sig-onprem                |3             |
|sig-service-catalog       |3             |
|sig-architecture          |2             |
|sig-Federation            |2             |
|sig-Azure                 |1             |
|sig-big-data              |1             |
|sig-Storage               |1             |
|sig-Testing               |1             |
|sig-ui                    |1             |
\--------------------------+--------------/
Rows: 38
real  0m27.565s
user  0m0.168s
sys 0m0.044s
```
- Last year (same result as for all data)
- Last month:
```
|sig-scalability           |527             |
|sig-cluster-lifecycle     |525             |
|sig-scheduling            |517             |
|sig-federation            |515             |
|sig-storage               |486             |
|sig-api-machinery         |470             |
|sig-cli                   |412             |
|sig-apps                  |256             |
|sig-network               |221             |
|sig-auth                  |214             |
|sig-node                  |182             |
|sig-release               |114             |
|sig-contributor-experience|62              |
|sig-testing               |31              |
|sig-aws                   |24              |
|sig-controller-manager    |21              |
|sig-windows               |13              |
|sig-cluster-ops           |11              |
|sig-OpenStack             |9               |
|sig-autoscaling           |8               |
|sig-instrumentation       |6               |
|sig-azure                 |4               |
|sig-architecture          |2               |
|sig-service-catalog       |2               |
|sig-Network               |1               |
|sig-openstack             |1               |
|sig-ui                    |1               |
```
- Last week:
```
|sig-scheduling            |174            |
|sig-api-machinery         |153            |
|sig-storage               |126            |
|sig-cluster-lifecycle     |115            |
|sig-federation            |103            |
|sig-auth                  |97             |
|sig-scalability           |93             |
|sig-node                  |75             |
|sig-network               |71             |
|sig-apps                  |59             |
|sig-cli                   |48             |
|sig-release               |14             |
|sig-contributor-experience|12             |
|sig-testing               |8              |
|sig-azure                 |3              |
|sig-aws                   |2              |
|sig-autoscaling           |1              |
|sig-instrumentation       |1              |
|sig-service-catalog       |1              |
```

2) Number of reviewers. Definded as number of authors adding `/lgtm` in comment or adding `lgtm` label (all of them takes <30 seconds, `time GHA2DB_PSQL=1 PG_PASS='pwd' ./runq.rb sql/reviewers_*.sql`):
- All Time: 506
```
2017-08-03 13:49:33 root@cncftest:/home/justa/dev/cncf/gha2db# time GHA2DB_PSQL=1 PG_PASS='pwd' ./runq.rb psql_metrics/reviewers_all_time.sql
/-----\
|count|
+-----+
|506  |
\-----/
Rows: 1
```
- Last year: 457
- Last month: 224
- Last week: 143

3) List reviewers (`time GHA2DB_PSQL=1 PG_PASS='pwd' ./runq.rb sql/list_*_reviewers.sql`):
- Takes <30s for all time, generates long list (not pasted here)

# Update/Sync tool

When You have imported all data You need - it needs to be updated periodically.
GitHub archive generates new file every hour.

Use `sync.rb`/`sync.sh` tool to update all Your data.

Example call:
- `GHA2DB_MYSQL=1 MYSQL_PASS='pwd' IDB_PASS='pwd' ./sync.sh`
- `GHA2DB_PSQL=1 PG_PASS='pwd' IDB_PASS='pwd' ./sync.sh`
- Add `GHA2DB_RESETIDB` environment variable to rebuild InfluxDB stats instead of update since last run
- Add `GHA2DB_SKIPIDB` environment variable to skip syncing InfluxDB (so it will only sync Postgres or MySQL)

`sync.sh` tool should be called by some kind of cron job to auto-update metrics every hour.

For now there is a manual script that can be used to loop sync every defined numeber of seconds, for example for sync every 30 minutes:

`GHA2DB_MYSQL=1 MYSQL_PASS='pwd' IDB_PASS='pwd' ./syncer.sh 1800`

# Grafana output

You can visualise data using Grafana, see `./grafana/` directory:

# Install Grafana using:
- Follow: http://docs.grafana.org/installation/debian/
- wget https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana_4.4.3_amd64.deb
- sudo dpkg -i grafana_4.4.3_amd64.deb
- sudo service grafana-server start
- Note that default verion installed by `apt-get install grafana` is very old and have drag&drop related bug.

# Install & configure InfluxDB:
- Install InfluxDB locally via `apt-get install influxdb`
- Start InfluxDB using `INFLUXDB_PASS='password' ./grafana/influxdb_setup.sh`.
- Feed InfluxDB from Postgres: `GHA2DB_PSQL=1 GHA2DB_RESETIDB=1 PG_PASS='pwd' IDB_PASS='pwd' ./sync.sh`
- Or Feed InfluxDB from MySQL: `GHA2DB_MYSQL=1 GHA2DB_RESETIDB=1 MYSQL_PASS='pwd' IDB_PASS='pwd' ./sync.sh`
- Output will be at: <https://cncftest.io>, for example: <https://cncftest.io/dashboard/db/reviewers?orgId=1>

# To drop & recreate InfluxDB:
- `INFLUXDB_PASS='idb_password' ./grafana/influxdb_recreate.sh`
- `GHA2DB_RESETIDB=1 GHA2DB_MYSQL=1 MYSQL_PASS='pwd' IDB_PASS='pwd' ./sync.sh`
- Then eventually start syncer: `GHA2DB_MYSQL=1 MYSQL_PASS='pwd' IDB_PASS='pwd' ./syncer.sh 1800`

# Alternate solution with Docker:
- Start Grafana using `GRAFANA_PASS='password' grafana/grafana_start.sh` to install Grafana & InfluxDB as docker containers (this requires Docker).
- Start InfluxDB using `INFLUXDB_PASS='password' ./grafana/influxdb_setup.sh`, this requires Docker & previous command succesfully executed.
- To cleanup Docker Grafana image and start from scratch use `./grafana/docker_cleanup.sh`. This will not delete Your grafana config because it is stored in local volume `/var/lib/grafana`.
- To recreate all Docker Grafana/InfluxDB stuff from scratch do: `GRAFANA_PASS='' INFLUXDB_PASS='' GHA2DB_PSQL=1 GHA2DB_RESETIDB=1 PG_PASS='' IDB_PASS='' ./grafana/reinit.sh`

# Feeding InfluxDB & Grafana:

Feed InfluxDB using:
- `GHA2DB_PSQL=1 PG_PASS='psql_pwd' IDB_PASS='influxdb_pwd' ./db2influx.rb reviewers_w psql_metrics/reviewers.sql '2015-08-03' '2017-08-21' w`
- `GHA2DB_MYSQL=1 MYSQL_PASS='mysql_pwd' IDB_PASS='influxdb_pwd' ./db2influx.rb sig_metions_data mysql_metrics/sig_mentions.sql '2017-08-14' '2017-08-21' d`
- First parameter is used as exact series name when metrics query returns single row with single column value.
- First parameter is used as function name when metrics query return mutiple rows, each with two columns. This function receives data row and period name and should return series name and value.
- Second parameter is a metrics SQL file, it should contain time conditions defined as `'{{from}}'` and `'{{to}}'`.
- Next two parameters are date ranges.
- Last parameter can be d, w, m, y (day, week, month, year).
- This tool uses environmental variables starting with `IDB_`, please see `idb_conn.rb` and `db2influx.rb` for details.
- `IDB_` variables are exactly the same as `PG_` and `MYSQL_` to set host, databaxe, user name, password.

# To check esults in the InfluxDB:
- influx
- auth (gha_admin/influxdb_pwd)
- use gha
- select * from reviewers
- select count(*) from reviewers
- show tag keys
- show field keys

# To drop data from InfluxDB:
- drop measurement reviewers
- drop series from reviewers

# Grafana dashboards
Grafana allows to save dashboards to JSON files.
There are few defined dashboards in `grafana/dashboard/` directory.

Currently:
- Reviewers dashboard: `reviewers.sql`
- SIG mentions dashboard `sig_metntions.json`
- Number of PRs merged in all Kubernetes repos `all_prs_merged.json`
- Number of PRs merged per repository `prs_merged.json`
- Average time from PR open to merge `time_to_merge.json`

# To enable SSL Grafana:
- First You need to install certbot, this is for example for Apache on Ubuntu 17.04:
- `sudo apt-get update`
- `sudo apt-get install software-properties-common`
- `sudo add-apt-repository ppa:certbot/certbot`
- `sudo apt-get update`
- `sudo apt-get install python-certbot-apache`
- `sudo certbot --apache`
- Then You need to proxy Apache https/SSL on prot 443 to http on port 3000 (this is where Grafana listens)
- Then You need to proxy Apache https/SSL on prot 10443 to http on port 8086 (this is where InfluxDB server listens)
- Modified Apache config files are in `grafana/apache`, You need to check them and enable something similar on Your machine.
- Your data source lives in https://<your_domain>:10443 (and https is served by Apache proxy to InfluxDB https:10443 -> http:8086)
- Your Grafana lives in https://<your_domain> (and https is served by Apache proxy to Grafana https:443 -> http:3000)
- Files in `grafana/apache` should be copied to `/etc/apache2` (see comments starting with `LG:`) and then `service apache2 restart`

# Grafana anonymous login

To enable Grafana anonymous login, do the foloowoing:
- Edit Grafana config file: `/etc/grafana/grafana.ini`
- Make sure You have options enabled:
```
[auth.anonymous]
enabled = true
org_name = Main Org.
org_role = Viewer
```
- `service grafana-server restart`
