# GitHub Archives to PostgreSQL

This tools filters GitHub archive for given date period and given organization, repository and saves results into JSON files.

Usage:
./gha2pg.rb YYYY-MM-DD HH YYYY-MM-DD HH [org [repo]]

First two parameters are date from:
- YYYY-MM-DD
- HH

Next two parameters are date to:
- YYYY-MM-DD
- HH

Both next two parameters are optional:
- org (if given and non empty '' then only return JSONs matching given org). You can also provide a comma separated list of orgs here: 'org1,org2,org3'
- repo (if given and non empty '' then only return JSONs matching given repo). You can also provide a comma separated list of repos here: 'repo1,repo2'

You can filter only by org by passing for example 'kubernetes' for org and '' for repo or skipping repo.
You can filter only by repo, You need to pass '' as org and then repo name.
You can return all JSONs by skipping both params.
You can provide both to observe only events from given org/repo.

# Configuration

You can tweak `gha2pg.rb` by:

- Set `$db_out = true` if You want to put int PSQL DB.
- Set `$json_out = true` to save output JSON files.
- Set `$debug` to: 1: You will see events data being processed, 2: You will also see all DB queries.

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

For example cncftest.io server has 48 CPU cores.
It will just process 48 hours in parallel.
It detects number of available CPUs automatically.

# Results

JSON:
Usually there are about 25000 GitHub events in single hour in Jan 2017 (for July 2017 it is 40000).
Average seems to be from 15000 to 50000.
Running this program on a 5 days of data with org `kubernetes` (and no repo set - which means all kubernetes repos).

- Takes: 10 minutes 50 seconds.
- Generates 12002 JSONs in `jsons/` directory with summary size 165 Mb (each JSON is a single GitHub event).
- To do so it processes about 21 Gb of data.
- XZipped file: `kubernetes_events.tar.xz`.

Running this program 1 month of data with org `kubernetes` (and no repo set - which means all kubernetes repos).
June 2017:

- Takes: 61 minutes 26 seconds.
- Generates 60773 JSONs in `jsons/` directory with summary size 815 Mb (each JSON is a single GitHub event).
- To do so it processes about 126 Gb of data.
- XZipped file: `k8s_month.tar.xz`.

Taking all event from single day is 5 minutes 50 seconds (2017-07-28):
- Generates 1194599 JSON files (1.2M)
- Takes 7 Gb of disck space

PostgreSQL (wip):
- Processing on 48 CPUS with all events for 3 days (1st, 2nd, 3rd Jan 2017):
- Takes 28 minutes 30 seconds.
- Creases 2,13M rows in `gha_events` table (DB is `gha`).
- Creates 367K rows in `gha_actors` table.
- Creates 438K rows in `gha_repos` table.

Running on all `kubernetes` repos for June 2017 yields:
- Takes: 66 minutes 24 seconds.
- Creates 4429 actors.
- Creates 4288 commits.
- Creates 60722 events.
- Creates 1 org.
- Creates 30 pages.
- Creates 58357 payloads.
- Creates 41 repos.
- Creates 4953 payload - commit connections.
- Creates 30 payloads - pages connections.

Running on all 3 kubernetes orgs (and my org 'lukaszgryglicki') for 1-29 July 2017 yields:


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
- Plan is to finish PostgreSQL database support and save matching JSONs there.
- Update analysis tool to recursivelly check Hash keys structure (without values) to see if they are the same in different event type's payloads.

