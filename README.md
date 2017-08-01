# GitHub Archives to PostgreSQL

Author: Łukasz Gryglicki <lukaszgryglick@o2.pl>

This tools filters GitHub archive for given date period and given organization, repository and saves results into JSON files.

Usage:

`./gha2pg.rb YYYY-MM-DD HH YYYY-MM-DD HH [org [repo]]`

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

You can tweak `gha2pg.rb` by:

- Set `$db_out = true` if You want to put int PSQL DB.
- Set `$json_out = true` to save output JSON files.
- Set `$debug` to: 1: You will see events data being processed, 2: You will also see all DB queries.
- Set `GHA2PG_ST` environment variable to run single threaded version

Examples in this shell script (some commented out, some not):

`time PG_PASS=your_pass ./gha2pg.sh`

# Informations

GitHub archives keeps data as Gzipped JSONs for each hour (24 gzipped JSONs per day).
Single JSON is not a real JSON file, but "\n" newline separated list of JSONs for each GitHub event in that hour.
So this is a JSON array in reality.

We download this gzipped JSON, process it on the fly, creating array of JSON events and
then each single event JSON matching org/repo criteria is saved in `jsons` directory as
`N_ID.json` where:
- N - given GitHub archive''s JSON hour as UNIX timestamp
- ID - GitHub event ID

Once saved, You can review those JSONs manually (they''re pretty printed)

# Mutithreading

For example <http://cncftest.io> server has 48 CPU cores.
It will just process 48 hours in parallel.
It detects number of available CPUs automatically.

# Results

JSON:

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

PostgreSQL:

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
- See <http://cncftest.io/all_3days_psql.sql.xz>

3) Running on 3 Kubernetes orgs for 2017-01-01 - 2017-08-01:
- Takes 7 hours 30 minutes.
- Generates 455321 events.


# PostgreSQL database
Setup:

Ubuntu like Linux:

- apt-get install postgresql 
- sudo -i -u postgres
- psql
- create database gha;
- create user gha_admin with password 'your_password_here';
- grant all privileges on database "gha" to gha_admin;
- ./structure.rb
- psql gha

`structure.rb` script is used to create Postgres database schema.
It gets connection details from environmental variables and falls back to some defaults.

Defaults are:
- Database host: environment variable PG_HOST or `localhost`
- Database port: PG_PORT or 5432
- Database name: PG_DB or 'gha'
- Database user: PG_USER or 'gha_admin'
- Database password: PG_PASS || 'password'

Typical internal usage: 
`time PG_PASS=your_password ./structure.rb`

Alternatively You can use `structure.sql` to create database structure.

# Database structure

You can see database structure in `structure.rb` or `structure.sql`.

Main idea is that we divide tables into 2 groups:
- const: meaning that data in this table is not changing in time (is saved onece)
- variable: meaning that data in those tables can change between GH events, and GH event_id is a part of this tables primary keys.

List of tables:
- gha_actors: const, users table
- gha_assets: variable, assets
- gha_branches: varbiable, branches data
- gha_comments: const, comments (issue, PR, review)
- gha_commits: variable, commits
- gha_events: const, single GitHub archive event
- gha_events_commits: variable, event's commits
- gha_events_pages: variable, event's pages
- gha_forkees: variable, forkee, repo state
- gha_issues: variable, issues
- gha_issues_assignees: variable, issue assignees
- gha_issues_labels: variable, issue labels
- gha_labels: const, labels
- gha_milestones: variable, milestones
- gha_orgs: const, orgs
- gha_pages: variable, pages
- gha_payloads: const, event payloads
- gha_pull_requests: variable, pull requests
- gha_pull_requests_assignees: variable pull request assignees
- gha_pull_requests_requested_reviewers: variable, pull request requested reviewers
- gha_releases: variable, releases
- gha_releases_assets: variable, release assets
- gha_repos: const, repos

# JSON structure analysis tool
There is also an internal tool: `analysis.rb`/`analysis.sh` to figure out how to create psql tables for gha.
But this is only useful while developing this tool.

This tool can generate all possible distinct structures of any key at any depths, to see possible veriants of this key.
It is used very intensively during development of PSQL table structure.

# Running on Kubernetes

Kubernetes consists of 3 different orgs, so to gather data for Kubernetes You need to provide them comma separated.

For example June 2017:

`time PG_PASS=pwd ./gha2pg.rb 2017-06-01 0 2017-07-01 0 'kubernetes,kubernetes-incubator,kubernetes-client'`


# Future
- Do some real queries and optimize them by adding `index` where needed.
- Foreign keys are slowing things down and I'm almost sure they're not needed in such kind of database.

