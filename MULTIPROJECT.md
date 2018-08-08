# Multiple Grafanas

You can run multiple Grafana instances using grafana/*/grafana_start.sh
You need to install Grafana and then create separate directories for all projects:
- `cp -R /usr/share/grafana /usr/share/grafana.projectname`.
- `cp -R /var/lib/grafana /var/lib/grafana.projectname`.
- `cp -R /etc/grafana /etc/grafana.projectname`.

# Grafana sessions in Postgres

To enable storing Grafana session in Postgres database do (setting cookie names is not enough):
- `sudo -u postgres psql`
- `create database projectname_grafana_sessions;`
- `grant all privileges on database "projectname_grafana_sessions" to gha_admin;`
- `\q'
- You need to do the for all projects. Replace projectname with the current project.
- `sudo -u postgres psql projectname_grafana_sessions`
```
create table session(
  key char(16) not null,
  data bytea,
  expiry integer not null,
  primary key(key)
);
```
- `grant all privileges on table "session" to gha_admin;`
- This table and grant permission is also saved as `util_sql/grafana_session_table.sql`, so you can use: `sudo -u postgres psql projectname_grafana_sessions < util_sql/grafana_session_table.sql`.
- You need to do the for all projects. Replace projectname with current project.
- Your password should NOT contain # or ;, because Grafana is unable to escape it correctly.
- To change password do: `sudo -u postgres psql` and then `ALTER ROLE gha_admin WITH PASSWORD 'new_pwd';`.
```
provider = postgres
provider_config = user=gha_admin host=127.0.0.1 port=5432 dbname=projectname_grafana_sessions sslmode=disable password=...
```
- This is sometimes tricky to see why connection to Postgres fail. To be able to debug it do:
- `source /etc/default/grafana-server`
- `cd /usr/share/grafana`
- `/usr/sbin/grafana-server --config=${CONF_FILE} --pidfile=${PID_FILE_DIR}/grafana-server.pid cfg:default.paths.logs=${LOG_DIR} cfg:default.paths.data=${DATA_DIR} cfg:default.paths.plugins=${PLUGINS_DIR}`
- You should also add: `max_connections = 300` to `/etc/postgresql/X.Y/main/postgresql.conf`. Default is 100.
- `service postgresql restart`
- This is all done as a part of standard deploy script see: `./devel/deploy_all.sh`.
