# Configuration for running multiple projects on single host
- You need to install docker (see instruction for your Linux distro).
- Start 2nd Grafna in a docker containser via `./grafana/docker_grafana_start.sh` (there are also `docker_grafana_stop.sh` and `docker_grafana_shell.sh` scripts)
- Configure Grafana using http:/{{your_domain}}:3001 as described in [GRAFANA.md](https://github.com/cncf/devstats/blob/master/GRAFANA.md), note changes specific to docker listed below:
- InfluxDB name should point to 2nd, 3rd ... project Influx database, for example "prometheus"
- You won't be able to access InfluxDB running on localhost, You need to get host's virtual address from within docker container:
- `./grafana/docker_grafana_shell.sh` and execute: `ip route | awk '/default/ { print $3 }'` to get container's gateway address (our host), for example `172.17.0.1`.
- Use http://{{gateway_ip}}:8086 as InfluxDB url.
