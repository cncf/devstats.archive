# Adding new project

This file describes how to add new project on the test and production servers.

## To add new project on the production (when already added on the test), you should use automatic deploy script:

- Make sure that you have Postgres database backup generated on the test server (this happens automatically on full deploy and nightly).
- Make sure you have Grafana DB dumps available on the test server by running `./grafana/copy_grafana_dbs.sh`.
- Commit to `production` branch with `[deploy]` in the commit message. Automatic deploy will happen. After successfull deploy start Grafana `./grafana/newproj/grafana_start.sh &`.
- Or manually run `CUSTGRAFPATH=1 PG_PASS=... GET=1 AGET=1 GGET=1 SKIPTEMP=1 TEMPRENAME=1 ./devel/deploy_all.sh` script with correct env variables after `make install`.
- Go to `https://newproject.devstats.cncf.io` and change Grafana and PostgreSQL passwords (default deploy copies database from the test server, so it has test server credentials initially).
- `./devel/put_all_charts.sh` then `./devel/put_all_charts_cleanup.sh`.

## To add a new project on the test server follow instructions:

- Do not commit changes until all is ready, or commit with `[no deploy]` in the commit message.
- Add project entry to `projects.yaml` file. Find projects orgs, repos, select start date, eventually add test coverage for complex regular expression in `regexp_test.go`.
- To identify repo and/or org name changes, date ranges for entrire projest use `util_sh/(repo|org)_name_changes_bigquery.sh org|org/repo`.
- Main repo can be empty `''` - in this case only two annotations will be added: 'start date - CNCF join date' and 'CNCF join date - now".
- CNCF join dates are listed [here](https://github.com/cncf/toc#projects).
- Update projects list files: `devel/all_prod_dbs.txt devel/all_prod_projects.txt devel/all_test_dbs.txt devel/all_test_projects.txt CONTRIBUTORS.md` and project icon type `devel/get_icon_type.sh`.
- Add this new project config to 'All' project in `projects.yaml all/psql.sh grafana/dashboards/all/dashboards.json scripts/all/repo_groups.sql util_sh/calculate_hours.sh`.
- Add entire new project as a new repo group in 'All' project.
- Update `cncf/gitdm:generate_actors.sh`.
- Add Google Analytics (GA) for the new domain and keep the `UA-...` code for deployment.
- Review `grafana/copy_artwork_icons.sh apache/www/copy_icons.sh grafana/create_images.sh grafana/change_title_and_icons_all.sh` - maybe you need to add special case. Icon related scripts are marked 'ARTWORK'.
- Copy setup scripts and then adjust them: `cp -R oldproject/ projectname/`, `vim projectname/*`. Most them can be shared for all projects in `./shared/`, usually only `psql.sh` is project specific.
- Update automatic deploy script: `./devel/deploy_all.sh`.
- Some projects should not be added to 'All CNCF' (like openconatiners, istio, spinnaker, knative), update `devel/deploy_proj.sh` in such cases.
- Copy `metrics/oldproject` to `metrics/projectname`. Update `./metrics/projectname/vars.yaml` file.
- `cp -Rv scripts/oldproject/ scripts/projectname`, `vim scripts/projectname/*`. Usually it is only `repo_groups.sql` and in simple cases it can fallback to `scripts/shared/repo_groups.sql`, you can skip copy then.
- `cp -Rv grafana/oldproject/ grafana/projectname/` and then update files. Usually `%s/oldproject/newproject/g|w|next`.
- `cp -Rv grafana/dashboards/oldproject/ grafana/dashboards/projectname/` and then update files.  Use `devel/mass_replace.sh` script, it contains some examples in the comments.
- Something like this: `` MODE=ss0 FROM='"oldproject"' TO='"newproject"' FILES=`find ./grafana/dashboards/newproject -type f -iname '*.json'` ./devel/mass_replace.sh ``.
- Update `grafana/dashboards/proj/dashboards.json` for all already existing projects, add new project using `devel/mass_replace.sh` or `devel/replace.sh`.
- For example: `./devel/dashboards_replace_from_to.sh dashboards.json` with `FROM` file containing old links and `TO` file containing new links.
- When adding new dashboard to all projects, you can add to single project (for example "cncf") and then populate to all others via something like:
- `for f in `cat devel/all_test_projects.txt`; do cp grafana/dashboards/jaeger/new-contributors-table.json grafana/dashboards/$f/; done`, then: `FROM_PROJ=jaeger ./util_sh/replace_proj_name_tag.sh new-contributors-table.json`.
- You can mass update Grafana dashboards using `sqlitedb` tool: `ONLY="proj1 proj2 ..." ./devel/put_all_charts.sh`, then `devel/put_all_charts_cleanup.sh`. You need to use `ONLY` because there is no new project's Grafana yet.
- Update `partials/projects.html partials/projects_health.html metrics/all/sync_vars.yaml`. Test with: `ONLY="proj1 proj2 ..." PG_PASS=... ./devel/vars_all.sh`. In simpler cases you can use `./util_sh/generate_partials.sh`.
- Update numbe rof projects in `metrics/all/sync_vars.yaml`.
- Update Apache proxy and SSL files `apache/www/index_* apache/*/sites-enabled/* apache/*/sites.txt` files.
- Run deploy all script: `GHA2DB_PROJECTS_OVERRIDE="+proj1,+proj2" SKIPTEMP=1 CUSTGRAFPATH=1 PG_PASS=... ./devel/deploy_all.sh`. If succeeded `make install`.
- Bacause this can take few hours to complete (for a project 4 years old for example), run next sync manually. Get sync command from `crontab -l` and prepend it with `GHA2DB_RECENT_RANGE="4 hours"` to avoid missing GitHub API events.
- You can also deploy automatically from webhook (even on the test server), but it takes very long time and is harder to debug, see [continuous deployment](https://github.com/cncf/devstats/blob/master/CONTINUOUS_DEPLOYMENT.md).
- Open `newproject.teststats.cncf.io` login with admin/admin, change the default password and follow instructions from `GRAFANA.md`.
- Import `grafana/dashboards/proj/dashboards.json` dashboard on all remaining projects manually or use `sqlitedb` tool.
- For example to only import dashboards for the new project use: `ONLY=newproject DASHBOARDS='dashboards.json' ./devel/put_all_charts.sh`. Then eventually (on success): `./devel/put_all_charts_cleanup.sh`.
- Import all new projects dashboards from `grafana/dashboards/newproject/*.json`, then finally: `grafana/copy_grafana_dbs.sh`.
- You can also run: `./grafana/restart_all_grafanas.sh`.
- Final deploy script is: `./devel/deploy_all.sh`. It should do all deployment automatically on the prod server. Follow all code from this script (eventually run some parts manually, the final version should do full deploy OOTB).
- If added disabled project, remember to add it to `crontab -e` via `GHA2DB_PROJECTS_OVERRIDE="+new_disabled_project"`.

# Updating artwork icons

- When updating artwork icons after the deployment (which happens often when we wait for an artwork), follow instructions in `ARTWORK.md`.
