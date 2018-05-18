sqlite3:
  select title, slug, uid from dashboard order by title;
vim:
  :'<,'>s/^/- /g
  :'<,'>s:|\(.*\)|\(.*\):\: [\1.json](https\://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/\1.json), [view](https\://k8s.devstats.cncf.io/d/\2/\1?orgId=1):g
  ::'<,'>s:|\(.*\)|\(.*\):\: [\1.json](https\://github.com/cncf/devstats/blob/master/grafana/dashboards/prometheus/\1.json), [view](https\://prometheus.devstats.cncf.io/d/\2/\1?orgId=1):g
