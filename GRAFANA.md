# Grafana configuration

- Go to Grafana UI: `http://localhost:3000`
- Login as "admin"/"admin" (You can change passwords later).
- Choose add data source, then Add Influx DB with those settings:
- Name "yourname" and type "InfluxDB", url default "http://localhost:8086", access: "proxy", database "gha", user "gha_admin", password "your_influx_pwd", min time interval "1h"
- Test & save datasource, then proceed to dashboards.
- Click Home, Import dashboard, Upload JSON file, choose dashboards saved as JSONs in `grafana/dashboards/{{project}}dashboard_name.json`, data source "InfluxDB" and save.
- All dashboards are here: [kubernetes](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/), [prometheus](https://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/)
- Do the same for all defined dashboards. Use specific project tag, for example `kubernetes` or `prometheus`.
- Import main home for example [kubernetes dahsboard](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/dashboards.json).
- Choose Admin -> Preferences, name Your organization (for example set it to `XYZ`)
- Set You home dashboard to just imported "Dashboards".
- You can also **try** to use current [grafana.db](https://devstats.k8s.io/web/grafana.db) to import everything at once, but be careful, because this is file is version specific.
- When finished, copy final settings file `grafana.db`: `cp /var/lib/grafana/grafana.db /var/www/html/web/`, `chmod go+r /var/www/html/web/grafana.db` to be visible from web server.
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
