# Grafana configuration

- Go to Grafana UI: `http://localhost:3000`
- Login as "admin"/"admin" (you can change passwords later).
- Choose add data source, then Add PostgreSQL DB with those settings:
- Name "psql", Type "PostgreSQL", host "127.0.0.1:5432", database "projname", user "ro_user" (this is the select-only user for psql), password "your-psql-password", ssl-mode "disabled".
- Make sure to run `./devel/ro_user_grants.sh projname` to add `ro_user's` select grants for all psql tables in projectname.
- If doing this for the first time also create `ro_user` via `devel/create_ro_user.sh`.
- Click Home, Import dashboard, Upload JSON file, choose dashboards saved as JSONs in `grafana/dashboards/{{project}}dashboard_name.json`, data source "PostgreSQL" and save.
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

- To run multiple Grafana instances follow [MULTIPROJECT.md](https://github.com/cncf/devstats/blob/master/MULTIPROJECT.md).

# Patching Grafana

- `cd $GOPATH/src/github.com/grafana`.
- `git clone https://github.com/grafana/grafana.git`.
- `cd grafana`.
- `git reset --hard`.
- `git pull`.
- `git checkout -b patching`.
- `git apply $GOPATH/src/devstats/grafana/patches/teamplate_variable_value_optional_remove_from_url.patch`.
- `git diff`.
- `go run build.go setup`.
- `go run build.go build`.
- `apt install npm`.
- `npm install -g yarn`.
- `yarn install --pure-lockfile`.
- `yarn start` (blocks one terminal).
- `go get github.com/Unknwon/bra`
- `bra run` (blocks one terminal).
- `npm run jest`.
- `npm run karma`.
- `npm run test`
- `gem install fpm`
- `apt install rpm`.
- `go run build.go build package` (takes a long time).
- `cp dist/grafanaXXXXX.deb ~/dev/go/src/devstats`.
- `cd $GOPATH/src/devstats`.
- `./devel/update_grafanas.sh grafanaXXXXX.deb`.
- `rm -f rafanaXXXXX.deb`.

Contrib must be started manually:
- `cd ~/dev/cncf/contributors/`.
- `./grafana.sh &`.
