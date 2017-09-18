# gha2db installation on Mac

Prerequisites:
- [golang](https://golang.org), this tutorial uses Go 1.9
- [brew](https://brew.sh)
- [golint](https://github.com/golang/lint): `go get -u github.com/golang/lint/golint`
- [goimports](https://godoc.org/golang.org/x/tools/cmd/goimports): `go get golang.org/x/tools/cmd/goimports`
- Go InfluxDB client: install with: `go get github.com/influxdata/influxdb/client/v2`
- Go Postgres client: install with: `go get github.com/lib/pq`
- Go unicode text transform tools: install with: `go get golang.org/x/text/transform` and `go get golang.org/x/text/unicode/norm`
- Go YAML parser library: install with: `gopkg.in/yaml.v2`
- Wget: install with: `brew install wget`

1. Configure Go:
- For example add to `~/.bash_profile`:
```
GOPATH=$HOME/dev/go; export GOPATH
PATH=$PATH:$GOPATH/bin; export PATH
```
2. Go to $GOPATH/dev/go/src/ and clone gha2db there:
- `git clone https://github.com/cncf/gha2db.git`
3. If You want to make changes and PRs, please clone `gha2db` from GitHub UI, and the clone Your forked version instead, like this:
- `git clone https://github.com/your_github_username/gha2db.git`
6. Go to gha2db directory, so You are now in `~/dev/go/src/gha2db` directory and compile binaries:
- `make`
7. If compiled sucessfully then execute test coverage that doesn't need databases:
- `make test`
- Tests should pass.
8. Install binaries & metrics:
- `sudo make install`

9. Install Postgres database ([link](https://gist.github.com/sgnl/609557ebacd3378f3b72)):
- `brew doctor`
- `brew update`
- `brew install postgresql`
- `brew services start postgresql`
- `createdb gha`
- `psql gha`
10. Inside psql client shell:
- `create user gha_admin with password 'your_password_here';`
- `grant all privileges on database "gha" to gha_admin;`
- `alter user gha_admin createdb;`
11. Leave `psql` shell, and get newest Kubernetes database dump:
- `wget https://cncftest.io/web/k8s.sql.xz` (it is about 400Mb).
- `xz -d k8s.sql.xz` (uncompressed dump is more than 7Gb).
- `psql gha < k8s.sql` (restore DB dump)

12. Install InfluxDB time-series database ([link](https://docs.influxdata.com/influxdb/v0.9/introduction/installation/)):
- `brew update`
- `brew install influxdb`
- `ln -sfv /usr/local/opt/influxdb/*.plist ~/Library/LaunchAgents`
- `launchctl load ~/Library/LaunchAgents/homebrew.mxcl.influxdb.plist`
- Create InfluxDB user, database: `IDB_PASS='your_password_here' ./grafana/influxdb_setup.sh`

13. Databases installed, now You need to test if all works fine, use database test coverage:
- `IDB_DB=dbtest IDB_PASS=your_influx_pwd PG_DB=dbtest PG_PASS=your_postgres_pwd make dbtest`
- Tests should pass.

14. We have Both databases running and Go tools installed, let's try to sync database dump from cncftest.io manually:
- We need to prefix call with GHA2DB_LOCAL to enable using tools from "./" directory
- To import data for the first time (Influx database is empty and postgres database is at the state when Kubernetes SQL dump was made on [cncftest.io](https://cncftest.io)):
- `GHA2DB_LOCAL=1 PG_PASS=pwd ./reinit_all.sh`
- This can take a while (depending how old is psql dump `k8s.sql.xz` on [cncftest](https://cncftest.io).
- Command should be succesfull.

15. Now we need to setup cron job that will call sync every hour (10 minutes after 1:00, 2:00, ...)
- You need to open `crontab.entry` file, it looks like this:
```
10 * * * * PG_PASS="..." cron_gha2db_sync.sh 1> /tmp/gha2db_sync.out 2> /tmp/gha2db_sync.err
```
- You need to change "..." PG_PASS to the real postgres password value and copy this line.
- Now run `crontab -e` and put this line at the end of file and save.
- Cron job will update Postgres and InfluxDB databases at 0:10, 1:10, ... 23:10 every day.
- It outputs logs to `/tmp/gha2db_sync.out` and `/tmp/gha2db_sync.err` and also to gha Postgres database: into table `gha_logs`.
- Check database values and logs about 15 minutes after full hours, like 14:15:
- Check max event craeted date: `select max(created_at) from gha_events` and logs `select * from gha_logs order by dt desc limit 20`.

16. Install [Grafana](http://docs.grafana.org/installation/mac/)
- `brew update`
- `brew install grafana`
- `brew services start grafana`
- Go to Grafana UI: `http://localhost:30000`
- Login as "admin"/"admin" (You can change passwords later)
- Choose add data source, then Add Influx DB with those settings:
- Name and type "InfluxDB", url default "http://localhost:8086", access: "direct", database "gha", user "gha_admin", password "your_influx_pwd", min time interval "1h"
- Test & save datasource, then proceed to dashboards.
- Click Home, Import dashboard, Upload JSON file, choose dashboards saved as JSONs in `grafana/dashboards/dashboard_name.json`, data source "InfluxDB" and save.
- Do the same for all defined dashboards.
To enable Grafana anonymous login, do the following:
- Edit Grafana config file: `/usr/local/share/grafana/conf/defaults.ini` and/or `/usr/local/etc/grafana/grafana.ini`
- Make sure You have options enabled:
```
[auth.anonymous]
enabled = true
org_name = Main Org.
org_role = Viewer
```
- `brew services restart grafana`
- Go to Grafana UI (localhost:3000), choose sign out, and then access localhost:3000 again. You should be able to view dashboards as a guest now. To login again use http://localhost:3000/login.
- You can also enable SSL, to do so You need to follow SSL instruction in [USAGE](https://github.com/cncf/gha2db/blob/master/USAGE.md) (that requires domain name).

17. Now You can create new metrics (as SQL files and YAML definitions) and dashboards in Grafana (export as JSON).
18. PRs and suggestions are welcome, please create PRs and Issues on the [GitHub](https://github.com/cncf/gha2db).


# More details
- [README](https://github.com/cncf/gha2db/blob/master/README.md)
- [USAGE](https://github.com/cncf/gha2db/blob/master/USAGE.md)
