# Grafana configuration

- Go to Grafana UI: `http://localhost:3000`
- Login as "admin"/"admin" (You can change passwords later).
- Choose add data source, then Add Influx DB with those settings:
- Name "yourname" and type "InfluxDB", url default "http://localhost:8086", access: "proxy", database "gha", user "gha_admin", password "your_influx_pwd", min time interval "1h"
- Test & save datasource, then proceed to dashboards.
- Click Home, Import dashboard, Upload JSON file, choose dashboards saved as JSONs in `grafana/dashboards/{{project}}dashboard_name.json`, data source "InfluxDB" and save.
- All dashboards are here: [kubernetes](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/), [prometheus](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/), [opentracing](https://github.com/cncf/devstats/blob/master/grafana/dashboards/opentracing/).
- Do the same for all defined dashboards. Use specific project tag, for example `kubernetes`, `prometheus` or `opentracing`.
- Import main home for example [kubernetes dahsboard](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json).
- Choose Admin -> Preferences, name Your organization (for example set it to `XYZ`)
- Set You home dashboard to just imported "Dashboards".
- You can also **try** to use current [grafana.db](https://devstats.cncf.io/grafana.db.k8s) to import everything at once, but be careful, because this is file is version specific.
- When finished, copy final settings file `grafana.db`: `cp /var/lib/grafana/grafana.db /var/www/html/`, `chmod go+r /var/www/html/grafana.db` to be visible from web server.
- Change Grafana admin/admin credentials to something secure!

To enable Grafana anonymous login, do the following:
- Edit Grafana config file: `/etc/grafana/grafana.ini` or `/usr/local/share/grafana/conf/defaults.ini` or `/usr/local/etc/grafana/grafana.ini`:
- Make sure You have options enabled (replace `XYZ`: with Your organization name):
```
[auth.anonymous]
enabled = true
org_name = XYZ
org_role = Read Only Editor
```

To enable Google analytics:
google_analytics_ua_id = UA-XXXXXXXXX-1
- Restart grafana server.

To restrict using GRAFANA by server IP, for example 147.72.202.77:3000, You can set:
- `http_addr = 127.0.0.1`

This will only allow accessing Grafana from Apache proxy, please also see:
- [APACHE.md](https://github.com/cncf/devstats/blob/master/APACHE.md)
- [SSL.md](https://github.com/cncf/devstats/blob/master/SSL.md)

** This will *not* work for Grafana(s) running inside docker containers. **
To disallow access to docker containers from outside world you have to specify port mapping that only exposes port to localhost:
- Instead `-p 3001:3000` (that exposes 3001 to 0.0.0.0) use `127.0.0.1:3001`.

- To run multiple Grafana instances (for example to have multiple projects on the same host), You need to use Docker.
- Instructions here [MULTIPROJECT.md](https://github.com/cncf/devstats/blob/master/MULTIPROJECT.md).
- If want to secure InfluxDB and use Docker at the same time please see: [SECURE_INFLUXDB.md](https://github.com/cncf/devstats/blob/master/SECURE_INFLUXDB.md).
