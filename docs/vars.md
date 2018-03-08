# InfluxDB vars

- Per project variables can be defined [here](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/idb_vars.yaml) (kubernetes example).
- This is `metrics/{{project_name}}/idb_vars.yaml` for other projects.
- They use `idb_vars` [tool](https://github.com/cncf/devstats/blob/master/cmd/idb_vars/idb_vars.go), called [here](https://github.com/cncf/devstats/blob/master/kubernetes/reinit_all.sh#L4) (Kubernetes) or [here](https://github.com/cncf/devstats/blob/master/prometheus/reinit.sh#L4) (Prometheus).
- `idb_vars` can also be used for defining per project variables using OS commands results.
