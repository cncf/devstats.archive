# Adding new project

This file describes how to add new project on the test server.

To add new project on the production (when already added on the test), you should use automatic deploy script:
- Run `./devel/deploy_proj.sh` script with correct env variables or run deploy for all projects `devel/deploy_all.sh`.
- Go to `https://newproject.devstats.cncf.io` and change Grafana, InfluxDB and PostgreSQL passwords (default deploy copies database from the test server, so it has test server credentials initially).
- Reimport Home dashboard (which now contains link to a new project) on all existing projects.

To add a new project on the test server follow instructions:
- Run `sync_lock.sh`.
- Add project entry to `projects.yaml` file. Find projects orgs, repos, select start date, eventually add test coverage for complex regular expression in `regexp_test.go`.
- To identify repo and/or org name changes, date ranges for entrire projest use `util_sql/(repo|org)_name_changes_bigquery.sql` replacing name there.
- Main repo can be empty `''` - in this case only two annotations will be added: 'start date - CNCF join date' and 'CNCF join date - now".
- Set project databases (Influx and Postgres).
- CNCF join dates are listed here: https://github.com/cncf/toc#projects.
- Update projects list files: `devel/all_prod_dbs.txt devel/all_prod_projects.txt devel/all_test_dbs.txt devel/all_test_projects.txt`.
- Add this new project config to 'All' project in `projects.yaml all/psql.sh grafana/dashboards/all/dashboards.json scripts/all/repo_groups.sql devel/calculate_hours.sh`. Add entire new project as a new repo group in 'All' project.
- Add new domain for the project: `projectname.cncftest.io`. If using wildcard domain like `*.devstats.cncf.io` - this step is not needed.
- Add Google Analytics (GA) for the new domain and update /etc/grafana.projectname/grafana.ini with its `UA-...`.
- Review `grafana/copy_artwork_icons.sh apache/www/copy_icons.sh grafana/create_images.sh grafana/change_title_and_icons_all.sh` - maybe you need to add special case.
- Copy setup scripts and then adjust them: `cp -R oldproject/ projectname/`, `vim projectname/*`. Update automatic deploy script: `./devel/deploy_all.sh`.
- Copy `metrics/oldproject` to `metrics/projectname`. Update `./metrics/projectname/idb_vars.yaml` and `./metrics/projectname/pdb_vars.yaml` files.
- Please use Grafana's "null as zero" instead of using manuall filling gaps. This simplifies metrics a lot. Gaps filling is only needed when using data from > 1 Influx series.
- `cp -Rv scripts/oldproject/ scripts/projectname`, `vim scripts/projectname/*`.
- Run databases creation script: `PDB=1 IDB=1 GAPS=1 ./projectname/create_databases.sh`.
- Merge new project into 'All' project using `PG_PASS=pwd IDB_PASS=pwd IDB_HOST=172.17.0.1 ./all/add_project.sh projname org_name`.
- Run regenerate 'All CNCF' project InfluxData script `./all/reinit.sh`.
- `cp -Rv grafana/oldproject/ grafana/projectname/` and then update files. Usually `%s/oldproject/newproject/g|w|next`.
- `cp -Rv grafana/dashboards/oldproject/ grafana/dashboards/projectname/` and then update files.  Use `devel/mass_replace.sh` script, it contains some examples in the comments.
- You can use something like this: `MODE=ss0 FROM=`cat from` TO=`cat to` FILES=`find ./grafana/dashboards -type f -iname 'dashboards.json'` ./devel/mass_replace.sh`, files `from` and `to` should contain from -> to replacements.
- For other dashboards you can use: "MODE=ss0 FROM='"vitess"' TO='"nats"' FILES=`find ./grafana/dashboards/nats -type f -iname '*.json'` ./devel/mass_replace.sh".
- `make install` to install all changed stuff.
- Update `./projectname/create_grafana.sh` script to make it create correct Grafana installation.
- You now need Apache proxy and SSL, please follow instructions from APACHE.md and SSL.md
- Apache part is to update `apache/www/index_* apache/test/sites-enabled/* apache/prod/sites-enabled/*` files.
- SSL part is to issue certificate for new domain and setup proxy.
- Make sure to run `./devel/ro_user_grants.sh projname` to add `ro_user's` select grants for all psql tables in projectname.
- Start new grafana: `./grafana/projectname/grafana_start.sh &` or `killall grafana-server`, `./grafana/start_all_grafanas.sh`, `ps -aux | grep grafana-server`.
- Update Apache config to proxy https to new Grafana instance: `vim /etc/apache2/sites-enabled/000-default-le-ssl.conf`, `service apache2 restart`
- List of test SSL sites is in `./apache/test/sites.txt` and for prod `./apache/prod/sites.txt`.
- Issue new SSL certificate as described in `SSL.md` (test server): 'sudo certbot --apache -n --expand -d `cat apache/test/sites.txt`'.
- Or (prod server): 'sudo certbot --apache -d -n --expand `cat apache/prod/sites.txt`'.
- Or with standalone authenticator (test server): "sudo certbot -d -n --expand `cat apache/test/sites.txt` --authenticator standalone --installer apache --pre-hook 'service apache2 stop' --post-hook 'service apache2 start'".
- Or with standalone authenticator (prod server): "sudo certbot -d -n --expand `cat apache/prod/sites.txt` --authenticator standalone --installer apache --pre-hook 'service apache2 stop' --post-hook 'service apache2 start'".
- Open `newproject.cncftest.io` login with admin/admin, change the default password and follow instructions from `GRAFANA.md`.
- Add new project to `/var/www/html/index.html`.
- Update and import `grafana/dashboards/{{proj}}/dashboards.json` dashboard on all remaining projects.
- Finally: `cp /var/lib/grafana.projectname/grafana.db /var/www/html/grafana.projectname.db` and/or `grafana/copy_grafana_dbs.sh`
- `sync_unlock.sh`.
- Final deploy script is: `./devel/deploy_all.sh`. It should do all deployment automatically on the prod server. Follow all code from this script (eventually run some parts manually, the final version should do full deploy OOTB).
