# Adding new project
  
To add new project follow instructions:
- Add project entry to `projects.yaml` file. Find projects orgs, repos, select start date.
- Add project entry in `crontab.entry` but do not install new cron yet (that will be the last step).
- Add new domain for the project: `projectname.cncftest.io`.
- Search for all files defined for some existing project, for example `find . -iname "*prometheus*"`.
- Generate icons for new project: `./grafana/img/projectname32.png`, `./grafana/img/projectname.svg`.
- PNG should be 32bit RGBA 32x32 PNG.
- SVG should be color and square.
- Copy setup scripts and then adjust them:
- `cp -R prometheus/ projectname/`, `mv projectname/prometheus.sh projectname/projectname.sh`, `vim projectname/*`.
- To update project's `annotations.sh` you need to clone project's main repo somewhere and then list all its releases/tags to create final annotations file.
- Copy `metrics/prometheus` to `metrics/projectname`, those files will need tweaks too, but now update `metrics/projectname/annotations.yaml`.
- You can use something like this to get releases/tags on a GitHub repo: `git log --tags --simplify-by-decoration --pretty="format:%ai %d"`.
- `cp -Rv scripts/prometheus/ scripts/projectname`, `vim scripts/projectname/*`.
- create Postgres database for new project: `sudo -u postgres psql`
- `create database projectname;`
- `grant all privileges on database "projectname" to gha_admin;`
- Generate Postgres data: `PG_PASS=... IDB_PASS=... IDB_HOST=172.17.0.1 ./grpc/grpc.sh`.
