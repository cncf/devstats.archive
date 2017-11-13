# Configuration for running multiple projects on single host
- You need to install docker (see instruction for your Linux distro). This example uses `prometheus`, You can do the same for other projects by changing `prometheus` to othe r project (like `opentracing` for example).
- Start Grafana in a docker containser via `GRAFANA_PASS=... ./grafana/prometheus/docker_grafana_first_start.sh` (this is for first start when there are no `/etc/grafana.prometheus` and `/usr/share/grafana.prometheus` `directories yet).
- There are also `docker_grafana_run.sh`, `docker_grafana_start.sh`, `docker_grafana_stop.sh`, `docker_grafana_restart.sh`, `docker_grafana_shell.sh` scripts in `grafana/prometheus/`.
- Now You need to copy grafana config from the container to the host, do:
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
- Now You have container's config files in host `/var/lib/grafana.prometheus`, `/etc/grafana.prometheus` and `/var/lib/grafana.prometheus`.
- Stop temporary instance via `docker stop 62e71b9d33d6`.
- Start instance that uses freshly copied `/etc/grafana.prometheus` and `/usr/share/grafana.prometheus`: `./grafana/opentracing/docker_grafana_run.sh` and then `./grafana/prometheus/docker_grafana_start.sh`.
- Configure Grafana using http:/{{your_domain}}:3001 as described in [GRAFANA.md](https://github.com/cncf/devstats/blob/master/GRAFANA.md), note changes specific to docker listed below:
- InfluxDB name should point to 2nd, 3rd ... project Influx database, for example "prometheus".
- You won't be able to access InfluxDB running on localhost, You need to get host's virtual address from within docker container:
- `./grafana/prometheus/docker_grafana_shell.sh` and execute: `ip route | awk '/default/ { print $3 }'` to get container's gateway address (our host), for example `172.17.0.1`.
- This is also saved as `grafana/get_gateway_ip.sh`.
- Use http://{{gateway_ip}}:8086 as InfluxDB url.
- To edit `grafana.ini` config file (to allow anonymous access), you need to edit `/etc/grafana.prometheus/grafana.ini`.
- Instead of restarting the service via `service grafana-server restart` You need to restart docker conatiner via: `./grafana/prometheus/docker_grafana_restart.sh`.
- All standard grafanana folders are mapped into grafana.prometheus equivalents accessible on host to configure grafana inside docker container.
- Evereywhere when grafana server restart is needed, you should restart docker container instead.
