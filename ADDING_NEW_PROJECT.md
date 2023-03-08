## Adding new project

This file describes how to add new project on the test and production servers.

## To add new project on the production (when already added on the test), you should use automatic deploy script:

- Make sure that you have Postgres database backup generated on the test server (this happens automatically on full deploy and nightly).
- Make sure you have Grafana DB dumps available on the test server by running `./grafana/copy_grafana_dbs.sh`.
- Commit to `production` branch with `[deploy]` in the commit message. Automatic deploy will happen. After successfull deploy start Grafana `./grafana/newproj/grafana_start.sh &`.
- Or manually run `CUSTGRAFPATH=1 PG_PASS=... GET=1 SKIPTEMP=1 TEMPRENAME=1 HEALTH=1 ./devel/deploy_all.sh` script with correct env variables after `make install`.
- Go to `https://newproject.devstats.cncf.io` and change Grafana and PostgreSQL passwords (default deploy copies database from the test server, so it has test server credentials initially).
- `./devel/put_all_charts.sh` then `./devel/put_all_charts_cleanup.sh`.

## To add a new project on the test server follow instructions:

- Do not commit changes until all is ready, or commit with `[no deploy]` in the commit message.
- Add project entry to `projects.yaml` file. Find projects orgs, repos, select start date, eventually add test coverage for complex regular expression in `regexp_test.go`.
- To identify repo and/or org name changes, date ranges for entire project use `util_sh/(repo|org)_name_changes_bigquery.sh org|org/repo`. You may need to update `util_sql/(org_repo)_name_changes_bigquery.sql` to include newest months.
- Main repo can be empty `''` - in this case only two annotations will be added: 'start date - CNCF join date' and 'CNCF join date - now".
- CNCF join dates are listed [here](https://github.com/cncf/toc#projects).
- Update projects list files: `devel/all_prod_dbs.txt devel/all_prod_projects.txt devel/all_test_dbs.txt devel/all_test_projects.txt util_sh/affs_test.sh util_sh/affs_prod.sh CONTRIBUTORS.md devel/get_icon_type.sh devel/get_icon_source.sh devel/add_single_metric.sh`.
- Add this new project config to 'All' project in `projects.yaml all/psql.sh grafana/dashboards/all/dashboards.json scripts/all/repo_groups.sql util_sh/calculate_hours.sh`.
- Add entire new project as a new repo group in 'All' project.
- Add new project repo REGEXP in `util_data/project_re.txt` and command lines in `util_data/project_cmdline.txt`. `all` means `All CNCF`, everything means `All CNCF` + non-standard test projects.
- Update `all` and `everything` REGEXPs. Run `` ONLY=`cat devel/all_prod_projects.txt` SKIP=all ./util_sh/all_cncf_re.sh > out `` to get `all` value for all CNCF projects.
- Then run `SKIP=all ./util_sh/all_cncf_re.sh > out` to get everything value, replace `all,` with `everything,` and save as `util_data/project_re.txt`.
- Update `devel/generate_actors_nonlf.sh`, possibly other `devel/generate_actors_*.sh` files.
- Copy setup scripts and then adjust them: `cp -R oldproject/ projectname/`, `vim projectname/*`. Most them can be shared for all projects in `./shared/`, usually only `psql.sh` is project specific.
- Add Google Analytics (GA) for the new domain and keep the `UA-...` code for deployment.
- Review `grafana/copy_artwork_icons.sh apache/www/copy_icons.sh grafana/create_images.sh grafana/change_title_and_icons_all.sh` - maybe you need to add special case. Icon related scripts are marked 'ARTWORK'.
- Update automatic deploy script: `./devel/deploy_all.sh`.
- Some projects should not be added to 'All CNCF' (like openconatiners, istio, spinnaker, knative, linux, zephyr, sam, azf, riff, fn, openwhisk, openfaas, nodejs, cii), update `devel/deploy_proj.sh` in such cases.
- Copy `metrics/oldproject` to `metrics/projectname`. Update `./metrics/projectname/vars.yaml` file.
- `cp -Rv scripts/oldproject/ scripts/projectname`, `vim scripts/projectname/*`. Usually it is only `repo_groups.sql` and in simple cases it can fallback to `scripts/shared/repo_groups.sql`, you can skip copy then.
- `cp -Rv grafana/oldproject/ grafana/projectname/` and then update files. Usually `%s/Oldproject/Newproject/g`, `%s/oldproject/newproject/g|w|next`.
- Try to source from Grafana with most similar project start date: `cp -Rv grafana/dashboards/oldproject/ grafana/dashboards/projectname/` and then update files.  Use `devel/mass_replace.sh` script, it contains some examples in the comments.
- Something like this: `` MODE=ss0 FROM='"oldproject"' TO='"newproject"' FILES=`find ./grafana/dashboards/newproject -type f -iname '*.json'` ./devel/mass_replace.sh ``.
- For multiple projects at once: `` for f in wasmedge chaosblade vineyard antrea fluid submariner; do cp -Rv grafana/dashboards/porter/ "grafana/dashboards/${f}/"; MODE=ss0 FROM='"porter"' TO="\"${f}\"" FILES=`find "./grafana/dashboards/${f}/" -type f -iname '*.json'` ./devel/mass_replace.sh; done ``.
- Update `grafana/dashboards/proj/dashboards.json` for all already existing projects, add new project using `devel/mass_replace.sh` or `devel/replace.sh`.
- For example: `./devel/dashboards_replace_from_to.sh dashboards.json` with `FROM` file containing old links and `TO` file containing new links.
- When adding a new dashboard to all projects, you can add to single project (for example "cncf") and then populate to all others via something like: `FROM_PROJ=cncf ./devel/add_dashboard.sh dashboard-name.json`, or old approach:
- When adding a new dashboard remember to add `dashboard` and `project-slug` tags to it so it will be visible in `Dashboards` list.
- `` for f in `cat ../devstats-docker-images/k8s/all_test_projects.txt`; do cp grafana/dashboards/jaeger/new-contributors-table.json grafana/dashboards/$f/; done ``, then: `FROM_PROJ=jaeger ./util_sh/replace_proj_name_tag.sh new-contributors-table.json`.
- You can mass update Grafana dashboards using `sqlitedb` tool: `ONLY="proj1 proj2 ..." ./devel/put_all_charts.sh`, then `devel/put_all_charts_cleanup.sh`. You need to use `ONLY` because there is no new project's Grafana yet.
- When adding new dashboard to projects that use dashboards folders (like Kubernetes) update `cncf/devstats:grafana/proj/custom_sqlite.sql` file.
- To update all other projects' `vars.yaml` with a new documentation for the new dashboard do: `FROM="`cat ./FROM`" TO="`cat ./TO`" FILES=`find metrics/ -iname "vars.yaml"` MODE=ss0 ./devel/mass_replace.sh`.
- Update `partials/projects.html partials/projects_health.html metrics/all/sync_vars.yaml`. Test with: `ONLY="proj1 proj2 ..." PG_PASS=... ./devel/vars_all.sh`. In simpler cases you can use `./util_sh/generate_partials.sh`. Also check `util_sh/update_json_value.sh`.
- For updating `partials/projects.html` or `apache/www/index_*.html`, copy the Graduated/Incubating/Sandbox section into some text file and then `KIND=Graduated SIZE=9 ./tsplit < graduated.txt > new_graduated.txt`.
- If normalized project name is not equal to lower project name, you need to update projects health metric to do the mapping, for example `series_name_map: { clouddeploymentkitforkubernetes: cdk8s }`, see `metrics/*/*.yaml`.
- Update the number of projects in `metrics/all/sync_vars.yaml`.
- Update Apache proxy and SSL files `apache/www/index_* apache/*/sites-enabled/* apache/*/sites.txt` files. You can copy from `partials/projects.yaml` adn then: `:'<,'>s/\[\[hostname]]/devstats.cncf.io/g`, `:'<,'>s/public\/img\/projects\///g` and `:'<,'>s/devstats\.cncf\.io/teststats.cncf.io/g`.
- Generate new artwork icons: `[TEST_SERVER=1] ./devel/icons_all.sh`. On kubernetes/helm deployment do next: `Do all/everything command`.
- Run deploy all script: `GHA2DB_PROJECTS_OVERRIDE="+proj1,+proj2" SKIPCERT=1 HEALTH=1 SKIPTEMP=1 CUSTGRAFPATH=1 PG_PASS=... ./devel/deploy_all.sh`. If succeeded `make install`.
- Because this can take few hours to complete (for a project 6 years old for example), run next sync manually. Get sync command from `crontab -l` and prepend it with `GHA2DB_RECENT_RANGE="6 hours"` to avoid missing GitHub API events.
- You can also deploy automatically from webhook (even on the test server), but it takes very long time and is harder to debug, see [continuous deployment](https://github.com/cncf/devstats/blob/master/CONTINUOUS_DEPLOYMENT.md).
- Open `newproject.teststats.cncf.io` login with admin/admin, change the default password. Everything should be automatically populated, in case of any problems refer to `GRAFANA.md` file.
- You should visit all dashboards and adjust date ranges and for some dashboards automatically selected values.
- Final deploy script is: `./devel/deploy_all.sh`. It should do all deployment automatically on the prod server. Follow all code from this script (eventually run some parts manually, the final version should do full deploy OOTB).
- If added disabled project, remember to add it to `crontab -e` via `GHA2DB_PROJECTS_OVERRIDE="+new_disabled_project"`.
- Also add in other devstats repositories, follow `cncf/devstats-helm:ADDING_NEW_PROJECTS.md`.
- Update cncf/gitdm affiliations with [official project maintainers](http://maintainers.cncf.io/).

## Update shared Grafana data

- Create Grafana data for new project(s): `cp ../devstatscode/sqlitedb ../devstatscode/runq ../devstatscode/replacer grafana/ && tar cf devstats-grafana.tar grafana/runq grafana/sqlitedb grafana/replacer grafana/shared grafana/img/*.svg grafana/img/*.png grafana/*/change_title_and_icons.sh grafana/*/custom_sqlite.sql grafana/dashboards/*/*.json`.
- Note that if you added new projects links then you need to copy `grafana/dashboards/*/*.json` for all Grafana instances, not just the new ones - so the old Grafanas will have new links.
- SFTP it to devstats node: `sftp root@node-N`, `mput devstats-grafana.tar`. SSH into that node: `ssh root@node-N`, get static pod name: `k get po -n devstats-prod | grep static-prod`, `k get po -n devstats-test | grep static-test`.
- Copy new grafana data to that pod: `k cp devstats-grafana.tar -n devstats-prod devstats-static-prod-5779c5dd5d-2prpr:/devstats-grafana.tar`, shell into that pod: `k exec -itn devstats-prod devstats-static-prod-5779c5dd5d-2prpr -- bash`.
- Update shared grafana files: `` rm -rf /grafana && tar xvf /devstats-grafana.tar && cd /grafana/ && cp -v shared/* /usr/share/nginx/html/backups/grafana/shared/ && cp -v img/* /usr/share/nginx/html/backups/grafana/img/ && echo OK ``.
- If you want to update all dashboards: `rm -rf /usr/share/nginx/html/backups/grafana/dashboards/ && cp -Rv dashboards/ /usr/share/nginx/html/backups/grafana/dashboards`.
- Or copy dashboards manually: `` for f in merbridge devspace capsule zot paralus carina ko opcr werf kubescape; do echo $f; cp -Rv dashboards/$f/ /usr/share/nginx/html/backups/grafana/dashboards/$f; done ``.
- Or copy per-project files manually: `` for f in merbridge devspace capsule zot paralus carina ko opcr werf kubescape; do echo $f; cp -Rv $f/ /usr/share/nginx/html/backups/grafana/$f; done ``.
- Or all files at once: `rm -rf /usr/share/nginx/html/backups/grafana && mv /grafana /usr/share/nginx/html/backups/grafana && rm /devstats-grafana.tar`.
- Do all/everything command: `rm -rf /grafana && tar xf /devstats-grafana.tar && rm -rf /usr/share/nginx/html/backups/grafana && mv /grafana /usr/share/nginx/html/backups/grafana && rm /devstats-grafana.tar && chmod -R ugo+rwx /usr/share/nginx/html/backups/grafana/ && echo 'All OK'`.
- You need to do this for both `devstats-test` and `devstats-prod`.
- Per-project data: `` for f in prj1 prj2; do cp -Rv "$f/" "/usr/share/nginx/html/backups/grafana/$f"; cp -Rv "dashboards/$f/" "/usr/share/nginx/html/backups/grafana/dashboards/$f"; done ``.
- Permissions: `chmod -R ugo+rwx /usr/share/nginx/html/backups/grafana/`, cleanup: `rm -rf devstats-grafana.tar /grafana/`. Also `rm devstats-grafana.tar` locally.
- To get updated Grafana dashboards (saved using browser): `PROD=1 ONLY='clusterpedia opencost aerakimesh curve openfeature kubewarden devstream' ./devel/get_all_sqlite_jsons.sh`.

# Updating artwork icons

- When updating artwork icons after the deployment (which happens often when we wait for an artwork), follow instructions in `ARTWORK.md`.

# Graduating projects

- See [graduating instructions](https://github.com/cncf/devstats/blob/master/GRADUATING.md). This can also be used for moving to Incubation state or Archived state.
