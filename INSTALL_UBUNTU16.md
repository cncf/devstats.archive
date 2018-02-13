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
    - `sudo -u postgres pg_restore gha.dump` (restore DB dump)

9. Install InfluxDB time-series database ([link](https://docs.influxdata.com/influxdb/v0.9/introduction/installation/)):
    - Ubuntu 16 contains very old `influxdb` when installed by default `apt-get install influxdb`, so:
    - `curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -`
    - `source /etc/lsb-release`
    - `echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list`
    - `sudo apt-get update && sudo apt-get install influxdb`
    - `sudo service influxdb start`
    - Create InfluxDB user, database: `IDB_HOST="172.17.0.1" IDB_PASS='your_password_here' ./grafana/influxdb_setup.sh gha`
    - InfluxDB has authentication disabled by default.
    - Edit config file `vim /etc/influxdb/influxdb.conf` and change section `[http]`, `auth-enabled = true` and `[subscriber]` `http-timeout = "300s"`
    - If you want to disable external InfluxDB access (for any external IP, only localhost) follow those instructions [SECURE_INFLUXDB.md](https://github.com/cncf/devstats/blob/master/SECURE_INFLUXDB.md).
    - `sudo service influxdb restart`

10. Databases installed, you need to test if all works fine, use database test coverage:
    - `GHA2DB_PROJECT=kubernetes IDB_DB=dbtest IDB_HOST="172.17.0.1" IDB_PASS=your_influx_pwd PG_DB=dbtest PG_PASS=your_postgres_pwd make dbtest`
    - Tests should pass.

11. We have both databases running and Go tools installed, let's try to sync database dump from k8s.devstats.cncf.io manually:
    - Set reuse TCP connections (Golang InfluxDB may need this under heavy load): `sudo ./scripts/net_tcp_config.sh`
    - On some VMs `tcp_tw_recycle` will be unavailable, ignore the warning.
    - We need to prefix call with GHA2DB_LOCAL to enable using tools from "./" directory
    - You need to have GitHub OAuth token, either put this token in `/etc/github/oauth` file or specify token value via GHA2DB_GITHUB_OAUTH=deadbeef654...10a0 (here you token value)
    - If you really don't want to use GitHub OAuth2 token, specify GHA2DB_GITHUB_OAUTH=- - this will force tokenless operation (via public API), it is a lot more rate limited than OAuth2 which gives 5000 API points/h
    - To import data for the first time (Influx database is empty and postgres database is at the state when Kubernetes SQL dump was made on [k8s.devstats.cncf.io](https://k8s.devstats.cncf.io)):
    - `IDB_HOST="172.17.0.1" IDB_PASS=pwd PG_PASS=pwd ./kubernetes/reinit_all.sh`
    - This can take a while (depending how old is psql dump `gha.sql.xz` on [k8s.devstats.cncf.io](https://k8s.devstats.cncf.io). It is generated daily at 3:00 AM UTC.
    - Command should be successfull.

12. We need to setup cron job that will call sync every hour (10 minutes after 1:00, 2:00, ...)
    - You need to open `crontab.entry` file, it looks like this for single project setup (this is obsolete, please use `devstats` mode instead):
    ```
    8 * * * * PATH=$PATH:/path/to/your/GOPATH/bin GHA2DB_CMDDEBUG=1 GHA2DB_PROJECT=kubernetes IDB_HOST="172.17.0.1" IDB_PASS='...' PG_PASS='...' gha2db_sync 2>> /tmp/gha2db_sync.err 1>> /tmp/gha2db_sync.log
    20 3 * * * PATH=$PATH:/path/to/your/GOPATH/bin cron_db_backup.sh gha 2>> /tmp/gha2db_backup.err 1>> /tmp/gha2db_backup.log
    */5 * * * * PATH=$PATH:/path/to/your/GOPATH/bin GOPATH=/your/gopath GHA2DB_CMDDEBUG=1 GHA2DB_PROJECT_ROOT=/path/to/repo PG_PASS="..." webhook 2>> /tmp/gha2db_webhook.err 1>> /tmp/gha2db_webhook.log
    ```
    - For multiple projects you can use `devstats` instead of `gha2db_sync` and `cron/cron_db_backup_all.sh` instead of `cron/cron_db_backup.sh`.
    ```
    7 * * * * PATH=$PATH:/path/to/GOPATH/bin IDB_HOST="172.17.0.1" IDB_PASS="..." PG_PASS="..." devstats 2>> /tmp/gha2db_sync.err 1>> /tmp/gha2db_sync.log
    30 3 * * * PATH=$PATH:/path/to/GOPATH/bin cron_db_backup_all.sh 2>> /tmp/gha2db_backup.err 1>> /tmp/gha2db_backup.log
    */5 * * * * PATH=$PATH:/path/to/GOPATH/bin GOPATH=/go/path GHA2DB_CMDDEBUG=1 GHA2DB_PROJECT_ROOT=/path/to/repo GHA2DB_DEPLOY_BRANCHES="production,master" PG_PASS=... webhook 2>> /tmp/gha2db_webhook.err 1>> /tmp/gha2db_webhook.log
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
