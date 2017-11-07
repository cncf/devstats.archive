# devstats installation on Ubuntu

Prerequisites:
- Ubuntu 16.04 LTS (quite old, but longest support).
- [golang](https://golang.org), this tutorial uses Go 1.6
    - `apt-get update`
    - `apt-get install golang git psmisc`
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
    - Go InfluxDB client: install with: `go get github.com/influxdata/influxdb/client/v2`
    - Go Postgres client: install with: `go get github.com/lib/pq`
    - Go unicode text transform tools: install with: `go get golang.org/x/text/transform` and `go get golang.org/x/text/unicode/norm`
    - Go YAML parser library: install with: `go get gopkg.in/yaml.v2`

2. Go to $GOPATH/src/ and clone devstats there:
    - `git clone https://github.com/cncf/devstats.git`
    - Set reuse TCP connections (Golang InfluxDB may need this under heavy load): `./scripts/net_tcp_config.sh`
3. If you want to make changes and PRs, please clone `devstats` from GitHub UI, and clone your forked version instead, like this:
    - `git clone https://github.com/your_github_username/devstats.git`
6. Go to devstats directory, so you are in `~/dev/go/src/devstats` directory and compile binaries:
    - `make`
7. If compiled sucessfully then execute test coverage that doesn't need databases:
    - `make test`
    - Tests should pass.
8. Install binaries & metrics:
    - `sudo make install`

9. Install Postgres database ([link](https://gist.github.com/sgnl/609557ebacd3378f3b72)):
    - apt-get install postgresql 
    - sudo -i -u postgres
    - psql

10. Inside psql client shell:
    - `create database gha;`
    - `create user gha_admin with password 'your_password_here';`
    - `grant all privileges on database "gha" to gha_admin;`
    - `alter user gha_admin createdb;`
11. Leave `psql` shell, and get newest Kubernetes database dump:
    - `wget https://devstats.k8s.io/web/gha.sql.xz` (it is about 400Mb).
    - `xz -d gha.sql.xz` (uncompressed dump is more than 7Gb).
    - `sudo -u postgres psql gha < gha.sql` (restore DB dump)

12. Install InfluxDB time-series database ([link](https://docs.influxdata.com/influxdb/v0.9/introduction/installation/)):
    - Ubuntu 16 contains very old `influxdb` when installed by default `apt-get install influxdb`, so:
    - `curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -`
    - `source /etc/lsb-release`
    - `echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list`
    - `sudo apt-get update && sudo apt-get install influxdb`
    - `sudo service influxdb start`
    - Create InfluxDB user, database: `IDB_PASS='your_password_here' ./grafana/influxdb_setup.sh gha`

13. Databases installed, you need to test if all works fine, use database test coverage:
    - `GHA2DB_PROJECT=kubernetes IDB_DB=dbtest IDB_PASS=your_influx_pwd PG_DB=dbtest PG_PASS=your_postgres_pwd make dbtest`
    - Tests should pass.

14. We have both databases running and Go tools installed, let's try to sync database dump from devstats.k8s.io manually:
    - We need to prefix call with GHA2DB_LOCAL to enable using tools from "./" directory
    - To import data for the first time (Influx database is empty and postgres database is at the state when Kubernetes SQL dump was made on [devstats.k8s.io](https://devstats.k8s.io)):
    - `GHA2DB_PROJECT=kubernetes GHA2DB_LOCAL=1 IDB_PASS=pwd PG_PASS=pwd ./reinit_all.sh`
    - This can take a while (depending how old is psql dump `gha.sql.xz` on [devstats.k8s](https://devstats.k8s.io). It is generated daily at 3:00 AM UTC.
    - Command should be successfull.

15. We need to setup cron job that will call sync every hour (10 minutes after 1:00, 2:00, ...)
    - You need to open `crontab.entry` file, it looks like this:
    ```
    10 * * * * PATH=$PATH:/path/to/your/GOPATH/bin GHA2DB_PROJECT=kubernetes GHA2DB_CMDDEBUG=1 IDB_PASS='...' PG_PASS='...' gha2db_sync 2>> /tmp/gha2db_sync.err 1>> /tmp/gha2db_sync.log
    20 3 * * * PATH=$PATH:/path/to/your/GOPATH/bin cron_db_backup.sh gha 2>> /tmp/gha2db_backup.err 1>> /tmp/gha2db_backup.log
    */5 * * * * PATH=$PATH:/path/to/your/GOPATH/bin GOPATH=/your/gopath GHA2DB_CMDDEBUG=1 GHA2DB_PROJECT_ROOT=/path/to/repo PG_PASS="..." webhook 2>> /tmp/gha2db_webhook.err 1>> /tmp/gha2db_webhook.log
    ```
    - First crontab entry is for automatic GHA sync.
    - Second crontab entry is for automatic daily backup of GHA database.
    - Third crontab entry is for Continuous Deployment - this a Travis Web Hook listener server, it deploys project when specific conditions are met, details [here](https://github.com/cncf/devstats/blob/master/CONTINUOUS_DEPLOYMENT.md).
    - You need to change "..." PG_PASS and IDB_PASS to the real postgres password value and copy this line.
    - You need to change "/path/to/your/GOPATH/bin" to the value of "$GOPATH/bin", You cannot use $GOPATH in crontab directly.
    - Run `crontab -e` and put this line at the end of file and save.
    - Cron job will update Postgres and InfluxDB databases at 0:10, 1:10, ... 23:10 every day.
    - It outputs logs to `/tmp/gha2db_sync.out` and `/tmp/gha2db_sync.err` and also to gha Postgres database: into table `gha_logs`.
    - Check database values and logs about 15 minutes after full hours, like 14:15:
    - Check max event created date: `select max(created_at) from gha_events` and logs `select * from gha_logs order by dt desc limit 20`.

16. Install [Grafana](http://docs.grafana.org/installation/mac/)
    - Follow: http://docs.grafana.org/installation/debian/
    - `wget https://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana_4.5.1_amd64.deb`
    - `sudo apt-get install -y adduser libfontconfig`
    - `sudo dpkg -i grafana_4.5.1_amd64.deb`
    - `sudo service grafana-server start`
    - Configure Grafana, as described [here](https://github.com/cncf/devstats/blob/master/GRAFANA.md).
    - `service grafana-server restart`
    - Go to Grafana UI (localhost:3000), choose sign out, and then access localhost:3000 again. You should be able to view dashboards as a guest. To login again use http://localhost:3000/login.
    - Install Apache as described [here](https://github.com/cncf/devstats/blob/master/APACHE.md).
    - You can also enable SSL, to do so You need to follow SSL instruction in [SSL](https://github.com/cncf/devstats/blob/master/SSL.md) (that requires domain name).

17. To change all Grafana page titles (starting with "Grafana - ") and icons use this script:
    - `GRAFANA_DATA=/usr/share/grafana/ ./grafana/change_title_and_icons.sh`.
    - Replace `GRAFANA_DATA` with You Grafana data directory.
    - `service grafana-server restart`
    - In some cases browser and/or Grafana cache old settings in this case temporarily move Grafana's `settings.js` file:
    - `mv /usr/share/grafana/public/app/core/settings.js /usr/share/grafana/public/app/core/settings.js.old`, restart grafana server and restore file.

18. To enable Continuous deployment using Travis, please follow instructions [here](https://github.com/cncf/devstats/blob/master/CONTINUOUS_DEPLOYMENT.md).

19. You can create new metrics (as SQL files and YAML definitions) and dashboards in Grafana (export as JSON).
20. PRs and suggestions are welcome, please create PRs and Issues on the [GitHub](https://github.com/cncf/devstats).

# More details
- [README](https://github.com/cncf/devstats/blob/master/README.md)
- [USAGE](https://github.com/cncf/devstats/blob/master/USAGE.md)
