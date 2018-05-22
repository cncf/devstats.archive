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
    - Go Postgres client: install with: `go get github.com/lib/pq`
    - Go unicode text transform tools: install with: `go get golang.org/x/text/transform` and `go get golang.org/x/text/unicode/norm`
    - Go YAML parser library: install with: `go get gopkg.in/yaml.v2`
    - Go GitHub API client: `go get github.com/google/go-github/github`
    - Go OAuth2 client: `go get golang.org/x/oauth2`
    - Go SQLite3 client: `go get github.com/mattn/go-sqlite3`
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
    - `sudo -E make install`

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
    - Set bigger maximum number of connections, at least 200 or more: `/etc/postgresql/X.Y/main/postgresql.conf`. Default is 100. `max_connections = 300`.

8. Inside psql client shell:
    - `create user gha_admin with password 'your_password_here';`
    - `grant all privileges on database "gha" to gha_admin;`
    - `grant all privileges on database "devstats" to gha_admin;`
    - `alter user gha_admin createdb;`
    - `create extension if not exists pgcrypto;`
    - Leave the shell and create logs table for devstats: `psql devstats < util_sql/devstats_log_table.sql`.
    - `PG_PASS=... ONLY="devstats gha" ./devel/create_ro_user.sh`.
    - `PG_PASS=... ONLY="devstats gha" ./devel/create_psql_user.sh devstats_team`.
    - In case of problems both scripts (`create_ro_user.sh` and `create_psql_user.sh`) support `DROP=1`, `NOCREATE=1` env variables.

9. Leave `psql` shell, and get newest Kubernetes database dump:
    - `wget https://devstats.cncf.io/gha.dump`.
    - `mv gha.dump /tmp`.
    - `sudo -u postgres pg_restore -d gha /tmp/gha.dump` (restore DB dump)
    - `rm /tmp/gha.dump`

10. Databases installed, you need to test if all works fine, use database test coverage:
    - `GHA2DB_PROJECT=kubernetes PG_DB=dbtest PG_PASS=your_postgres_pwd make dbtest`
    - Tests should pass.

11. We have both databases running and Go tools installed, let's try to sync database dump from `k8s.devstats.cncf.io` manually:
    - We need to prefix call with `GHA2DB_LOCAL=1` to enable using tools from "./" directory
    - You need to have GitHub OAuth token, either put this token in `/etc/github/aoauth` file or specify token value via `GHA2DB_GITHUB_OAUTH=deadbeef654...10a0` (here you token value)
    - If you really don't want to use GitHub OAuth2 token, specify `GHA2DB_GITHUB_OAUTH=-` - this will force tokenless operation (via public API), it is a lot more rate limited than OAuth2 which gives 5000 API points/h
    - To import time-series data for the first time (Postgres database is at the state when Kubernetes SQL dump was made on [k8s.devstats.cncf.io](https://k8s.devstats.cncf.io)):
    - `PG_PASS=pwd ONLY=kubernetes ./devel/reinit.sh`
    - This can take a while (depending how old is psql dump `gha.sql.xz` on [k8s.devstats.cncf.io](https://k8s.devstats.cncf.io). It is generated daily at 3:00 AM UTC.
    - Command should be successfull.

12. We need to setup cron job that will call sync every hour (10 minutes after 1:00, 2:00, ...)
    - You need to open `crontab.entry` file, it looks like this for single project setup (this is obsolete, please use `devstats` mode instead):
    ```
    8 * * * * PATH=$PATH:/path/to/your/GOPATH/bin GHA2DB_CMDDEBUG=1 GHA2DB_PROJECT=kubernetes PG_PASS='...' gha2db_sync 2>> /tmp/gha2db_sync.err 1>> /tmp/gha2db_sync.log
    30 3 * * * PATH=$PATH:/path/to/your/GOPATH/bin cron_db_backup.sh gha 2>> /tmp/gha2db_backup.err 1>> /tmp/gha2db_backup.log
    */5 * * * * PATH=$PATH:/path/to/your/GOPATH/bin GOPATH=/your/gopath GHA2DB_CMDDEBUG=1 GHA2DB_PROJECT_ROOT=/path/to/repo PG_PASS="..." GHA2DB_SKIP_FULL_DEPLOY=1 webhook 2>> /tmp/gha2db_webhook.err 1>> /tmp/gha2db_webhook.log
    ```
    - For multiple projects you can use `devstats` instead of `gha2db_sync` and `cron/cron_db_backup_all.sh` instead of `cron/cron_db_backup.sh`.
    ```
    7 * * * * PATH=$PATH:/path/to/GOPATH/bin PG_PASS="..." devstats 2>> /tmp/gha2db_sync.err 1>> /tmp/gha2db_sync.log
    30 3 * * * PATH=$PATH:/path/to/GOPATH/bin cron_db_backup_all.sh 2>> /tmp/gha2db_backup.err 1>> /tmp/gha2db_backup.log
    */5 * * * * PATH=$PATH:/path/to/GOPATH/bin GOPATH=/go/path GHA2DB_CMDDEBUG=1 GHA2DB_PROJECT_ROOT=/path/to/repo GHA2DB_DEPLOY_BRANCHES="production,master" PG_PASS=... GHA2DB_SKIP_FULL_DEPLOY=1 webhook 2>> /tmp/gha2db_webhook.err 1>> /tmp/gha2db_webhook.log
    ```
    - First crontab entry is for automatic GHA sync.
    - Second crontab entry is for automatic daily backup of GHA database.
    - Third crontab entry is for Continuous Deployment - this a Travis Web Hook listener server, it deploys project when specific conditions are met, details [here](https://github.com/cncf/devstats/blob/master/CONTINUOUS_DEPLOYMENT.md).
    - You need to change "..." PG_PASS to the real postgres password value and copy this line.
    - You need to change "/path/to/your/GOPATH/bin" to the value of "$GOPATH/bin", you cannot use $GOPATH in crontab directly.
    - Run `crontab -e` and put this line at the end of file and save.
    - Cron job will update Postgres database at 0:10, 1:10, ... 23:10 every day.
    - It outputs logs to `/tmp/gha2db_sync.out` and `/tmp/gha2db_sync.err` and also to gha Postgres database: into table `gha_logs`.
    - Check database values and logs about 15 minutes after full hours, like 14:15:
    - Check max event created date: `select max(created_at) from gha_events` and logs `select * from gha_logs order by dt desc limit 20`.

13. Install [Grafana](http://docs.grafana.org/installation/mac/)
    - `brew update`
    - `brew install grafana`
    - `brew services start grafana`
    - Configure Grafana, as described [here](https://github.com/cncf/devstats/blob/master/GRAFANA.md).
    - `brew services restart grafana`
    - Go to Grafana UI (localhost:3000), choose sign out, and then access localhost:3000 again. You should be able to view dashboards as a guest. To login again use http://localhost:3000/login.
    - Install Apache as described [here](https://github.com/cncf/devstats/blob/master/APACHE.md).
    - You can also enable SSL, to do so you need to follow SSL instruction in [SSL](https://github.com/cncf/devstats/blob/master/SSL.md) (that requires domain name).

14. To change all Grafana page titles (starting with "Grafana - ") and icons use this script:
    - `GRAFANA_DATA=/usr/share/grafana/ ./grafana/{{project}}/change_title_and_icons.sh`.
    - `GRAFANA_DATA` can also be `/usr/share/grafana.prometheus/` or `/usr/share/grafana.opentracing` for example, see [MULTIPROJECT.md](https://github.com/cncf/devstats/blob/master/MULTIPROJECT.md).
    - Replace `GRAFANA_DATA` with you Grafana data directory.
    - `brew services restart grafana`
    - In some cases browser and/or Grafana cache old settings in this case temporarily move Grafana's `settings.js` file:
    - `mv /usr/share/grafana/public/app/core/settings.js /usr/share/grafana/public/app/core/settings.js.old`, restart grafana server and restore file.

15. To enable Continuous deployment using Travis, please follow instructions [here](https://github.com/cncf/devstats/blob/master/CONTINUOUS_DEPLOYMENT.md).

17. You can create new metrics (as SQL files and YAML definitions) and dashboards in Grafana (export as JSON).
18. PRs and suggestions are welcome, please create PRs and Issues on the [GitHub](https://github.com/cncf/devstats).

# More details
- [Local Development](https://github.com/cncf/devstats/blob/master/DEVELOPMENT.md).
- [README](https://github.com/cncf/devstats/blob/master/README.md)
- [USAGE](https://github.com/cncf/devstats/blob/master/USAGE.md)
