# Multiple Grafanas

You can run multiple Grafana instances using grafana/*/grafana_start.sh
You need to install Grafana and then create separate directories for all projects:
- `cp -R /usr/share/grafana /usr/share/grafana.projectname`.
- `cp -R /var/lib/grafana /var/lib/grafana.projectname`.
- `cp -R /etc/grafana /etc/grafana.projectname`.

# Configuration for running multiple projects on single host using Docker

This info is a bit outdated and not used anymore.

- You need to install docker (see instruction for your Linux distro). This example uses `prometheus`, you can do the same for other projects by changing `prometheus` to other project (like `opentracing` for example).
- Docker instructions [here](https://github.com/cncf/devstats/blob/master/DOCKER.md).
- Start Grafana in a docker containser via `GRAFANA_PASS=... ./grafana/prometheus/docker_grafana_first_run.sh` (this is for first start when there are no `/etc/grafana.prometheus` and `/usr/share/grafana.prometheus` `directories yet).
- There are also `docker_grafana_run.sh`, `docker_grafana_start.sh`, `docker_grafana_stop.sh`, `docker_grafana_restart.sh`, `docker_grafana_shell.sh` scripts in `grafana/prometheus/`.
- Now you need to copy grafana config from the container to the host, do:
- Run `docker ps`, new grafana instance has some rangom name, for example output can be like this:
```
docker ps
CONTAINER ID        IMAGE                    COMMAND             CREATED             STATUS              PORTS                    NAMES
62e71b9d33d6        grafana/grafana:master   "/run.sh"           6 seconds ago       Up 5 seconds        0.0.0.0:3002->3000/tcp   quirky_chandrasekhar
b415070c6aa8        grafana/grafana:master   "/run.sh"           19 minutes ago      Up 4 minutes        0.0.0.0:3001->3000/tcp   prometheus_grafana
```
- In this case new container is named `quirky_chandrasekhar` and has container id `62e71b9d33d6`
- Login to the container via `docker exec -t -i 62e71b9d33d6 /bin/bash`.
- Inside the container: `cp -Rv /etc/grafana/ /var/lib/grafana/etc.grafana.prometheus`.
- Inside the container: `cp -Rv /usr/share/grafana /var/lib/grafana/share.grafana.prometheus`.
- Then exit the container `exit`.
- Then in the host: `mv /var/lib/grafana.prometheus/etc.grafana.prometheus/ /etc/grafana.prometheus`.
- Then in the host: `mv /var/lib/grafana.prometheus/share.grafana.prometheus/ /usr/share/grafana.prometheus`.
- Now you have container's config files in host `/var/lib/grafana.prometheus`, `/etc/grafana.prometheus` and `/var/lib/grafana.prometheus`.
- Stop temporary instance via `docker stop 62e71b9d33d6`.
- Start instance that uses freshly copied `/etc/grafana.prometheus` and `/usr/share/grafana.prometheus`: `./grafana/prometheus/docker_grafana_run.sh` and then `./grafana/prometheus/docker_grafana_start.sh`.
- Configure Grafana using `http://{{your_domain}}:3001` as described in [GRAFANA.md](https://github.com/cncf/devstats/blob/master/GRAFANA.md), note changes specific to docker listed below:
- To edit `grafana.ini` config file (to allow anonymous access), you need to edit `/etc/grafana.prometheus/grafana.ini`.
- Instead of restarting the service via `service grafana-server restart` you need to restart docker conatiner via: `./grafana/prometheus/docker_grafana_restart.sh`.
- All standard Grafana folders are mapped into grafana.prometheus equivalents accessible on host to configure grafana inside docker container.
- Evereywhere when grafana server restart is needed, you should restart docker container instead.
- You should set instance name and all 3 cookie names (different for all dockerized grafanas): `vi /etc/grafana.{{project}}/grafana.ini`:
```
instance_name = {{project}}.cncftest.io
cookie_name = {{project}}_grafana_sess
cookie_username = {{project}}_grafana_user_test
cookie_remember_name = {{project}}_grafana_remember_test
```
- Remember to set those values differently on prod and test servers.

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
- If you are adding sessions to dockerized Grafana instance you need to set hostname `172.17.0.1`.
- This is sometimes tricky to see why connection to Postgres fail. To be able to debug it do:
- `source /etc/default/grafana-server`
- `cd /usr/share/grafana`
- `/usr/sbin/grafana-server --config=${CONF_FILE} --pidfile=${PID_FILE_DIR}/grafana-server.pid cfg:default.paths.logs=${LOG_DIR} cfg:default.paths.data=${DATA_DIR} cfg:default.paths.plugins=${PLUGINS_DIR}`
- To see error logs of dockerized Grafana do:
- `docker logs projectname_grafana`
- Something like this: `panic: pq: no pg_hba.conf entry for host "172.17.0.2", user "gha_admin", database "projectname_grafana_sessions"` mean that you need to add:
- Add `host all all 172.17.0.0/24 md5` to your `/etc/postgresql/X.Y/main/pg_hba.conf` to allow all dockerized Grafanas to acces Postgres (from 172.17.0.xyz) address.
- You also need to add: `listen_addresses = '*'` to `/etc/postgresql/X.Y/main/postgresql.conf`.
- You shaould also add: `max_connections = 200` to `/etc/postgresql/X.Y/main/postgresql.conf`. Default is 100.
- `service postgresql restart`
