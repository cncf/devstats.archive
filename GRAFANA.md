# Grafana configuration

- Go to Grafana UI: `http://localhost:3000`
- Login as "admin"/"admin" (You can change passwords later)
- Choose add data source, then Add Influx DB with those settings:
- Name and type "InfluxDB", url default "http://localhost:8086", access: "proxy", database "gha", user "gha_admin", password "your_influx_pwd", min time interval "1h"
- Test & save datasource, then proceed to dashboards.
- Click Home, Import dashboard, Upload JSON file, choose dashboards saved as JSONs in `grafana/dashboards/dashboard_name.json`, data source "InfluxDB" and save.
- Do the same for all defined dashboards.
- Import main home [dahsboard](https://github.com/cncf/gha2db/blob/master/grafana/dashboards/dashboards.json).
- Choose Admin -> Preferences, name Your organization (for example set it to `XYZ`)
- Set You home dashboard to just imported "Dashboards".

To enable Grafana anonymous login, do the following:
- Edit Grafana config file: `/etc/grafana/grafana.ini` or `/usr/local/share/grafana/conf/defaults.ini` or `/usr/local/etc/grafana/grafana.ini`:
- Make sure You have options enabled (replace `XYZ`: with Your organization name)
```
[auth.anonymous]
enabled = true
org_name = XYZ
org_role = Viewer
```
