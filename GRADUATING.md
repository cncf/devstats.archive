# Steps needed to graduate project

Those steps are generally needed to change project status (usually from `Incubating` to `Graduated` or from `Sandbox` to `Incubating`):

- Update status in `projects.yaml`.
- Add `graduated_date` or similar (`incubating_date`, `archived_date`).
- Change projects links order on all home dashboards. Take for example `grafana/dashboards/all/dashboards.json`, copy list of projects links into `FROM` file, change order accordingly and paste it into `TO` file.
- Run: `./devel/dashboards_replace_from_to.sh dashboards.json`.
- Put new home dashboards: `./devel/put_all_charts.sh` and then `./devel/put_all_charts_cleanup.sh`.
- Update files: `partials/projects.html partials/projects_health.html` (remember about `cncf-` classes/separators).
- Run to update partials: `PG_PASS=... ./devel/vars_all.sh`.
- Update test and production www index files: `apache/www/index_test.html apache/www/index_prod.html`. Possibly others too like for GraphQL.
- Install them as `/var/www/html/index.html` on test and production respectively: `cp apache/www/index_envname.html /var/www/html/index.html`.
- Install everything: `make install`.
