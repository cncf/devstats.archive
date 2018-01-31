# Securing InfluxDB

- Edit config file `vim /etc/influxdb/influxdb.conf` and change section [http] and change:
- If you use native Grafana: `bind-address = "127.0.0.1:8086"`. Address 0.0.0.0:8086 allows connecting from any external IP, while 127.0.0.1 only allows local connections.
- If you use Dockerized Grafana: bind-address = "{docker_gateway_ip}:8086" (for example `172.17.0.1`), obtain docker gateway IP using `grafana/get_gateway_ip.sh` while connected to the docker container via: `./grafana/{project}/docker_grafana_shell.sh`.
- Note that if using docker gateway ip default connection to influxDB will no longer work, so you will have to use `IDB_HOST="http://172.17.0.1"` everywhere when connecting to InfluxDB.
