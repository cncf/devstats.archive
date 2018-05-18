# SIG mentions dashboard

Links:
- Postgres SQL file: [sig_mentions.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/sig_mentions.sql).
- Series definition: [metrics.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml#L246-L252).
- Grafana dashboard JSON: [sig_mentions.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions.json).
- User documentation: [sig_mentions.md](https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions.md).
- Production version: [view](https://k8s.devstats.cncf.io/d/41/sig-mentions?orgId=1).
- Test version: [view](https://k8s.cncftest.io/d/41/sig-mentions?orgId=1).

# Description

- We're quering `gha_texts` table. It contains all 'texts' from all Kubernetes repositories.
- For more information about `gha_texts` table please check: [docs/tables/gha_texts.md](https://github.com/cncf/devstats/blob/master/docs/tables/gha_texts.md).
- We're counting distinct GitHub events (text related events: issue/PR/commit comments, PR reviews, issue/PR body texts, titles) that contain any SIG reference.
- We're groupping this by SIG.
- Regexp to match SIG is: `(?i)(?:^|\s)+(@kubernetes/sig-[\w\d-]+)(?:-bug|-feature-request|-pr-review|-api-review|-misc|-proposal|-design-proposal|-test-failure)s?(?:$|[^\w\d-]+)` with `(?i)(?:^|\s)+(@kubernetes/sig-[\w\d-]*[\w\d]+)(?:$|[^\w\d-]+)` fallback.
- Example sig mentions: `@kubernetes/sig-node-bug`, `@Kubernetes/sig-apps`.
- We're only looking for texts created between `{{from}}` and `{{to}}` dates. Values for `from` and `to` will be replaced with final periods described later.
- We're also excluding bots activity (see [excluding bots](https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md))
- Each row returns single value, so the metric type is: `multi_row_single_column`.
- Each row is in the format column 1: `sig_mentions_texts,SIGName`, column 2: `NumberOfSIGMentions`.
- This metric uses `multi_value: true`, so each SIG is saved under different column name in a TSDB series.

# Periods and time series

Metric usage is defined in metric.yaml as follows:
```
series_name_or_func: multi_row_single_column
sql: sig_mentions
periods: d,w,m,q,y
aggregate: 1,7
skip: w7,m7,q7,y7
multi_value: true
```
- It means that we should call Postgres metric [sig_mentions.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/sig_mentions.sql).
- We should expect multiple rows each with 2 columns: 1st defines output series name, 2nd defines value.
- See [here](https://github.com/cncf/devstats/blob/master/docs/periods.md) for periods definitions.
- The final series name would be: `sig_mentions_texts_[[period]]`. Where `[[period]]` will be from d,w,m,q,y,d7.
- Each of those series (for example `sig_mentions_texts_d7`) will contain multiple columns (each column represent single SIG) with time series data.
- Final query is here: [sig_mentions.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions.json#L117): `SELECT /^[[sigs]]$/ FROM \"sig_mentions_texts_[[period]]\" WHERE $timeFilter`.
- `$timeFiler` value comes from Grafana date range selector. It is handled by Grafana internally.
- `[[period]]` comes from Variable definition in dashboard JSON: [sig_mentions.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions.json#L184-L225).
- `[[sigs]]` comes from Variable definition in dashboard JSON: [sig_mentions.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions.json#L230-L248).
- Note that this is a multi value select and reqexp part `/^[[sigs]]$/` means that we want to see all values currently selected from the drop-down.
- SIGs come from the tags: `SHOW TAG VALUES WITH KEY = sig_mentions_texts_name`, this tag is defined here: [tags.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/tags.yaml#L44).
- For more informations about tags check [here](https://github.com/cncf/devstats/blob/master/docs/tags.md).
- Releases comes from Grafana annotations: [sig_mentions.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions.json#L43-L55).
- For more details about annotations check [here](https://github.com/cncf/devstats/blob/master/docs/annotations.md).
- Project name is customized per project, it uses `[[full_name]]` template variable [definition](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions.json#L251-L268) and is [used as project name](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions.json#L54).
- Per project variables are defined using `vars` tools, more info [here](https://github.com/cncf/devstats/blob/master/docs/vars.md).
