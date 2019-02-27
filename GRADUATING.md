# Steps needed to graduate project

Those steps are generally needed to change project status (usually from `Incubating` to `Graduated` or from `Sandbox` to `Incubating`):

- Update status in `projects.yaml`.
- Change projects links order on all home dashboards. Take for example `grafana/dashboards/all/dashboards.json`, copy list of projects links into `FROM` file, change order accordingly and paste it into `TO` file.
- Run: `./devel/dashboards_replace_from_to.sh dashboards.json`.
- Put new home dashboards: `./devel/put_all_charts.sh` and then `./devel/put_all_charts_cleanup.sh`.
