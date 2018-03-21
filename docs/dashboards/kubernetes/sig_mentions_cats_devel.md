# SIG mentions categories dashboard

Links:
- Postgres SQL files: [sig_mentions_cats.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/sig_mentions_cats.sql) and [sig_mentions_breakdown.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/sig_mentions_breakdown.sql).
- InfluxDB series definition: [metrics.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml). Search for `sig_mentions_cats` and `sig_mentions_breakdown`.
- Grafana dashboard JSON: [sig_mentions_categories.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_categories.json).
- User documentation: [sig_mentions_cats.md](https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions_cats.md).
- Production version: [view](https://k8s.devstats.cncf.io/d/40/sig-mentions-categories?orgId=1).
- Test version: [view](https://k8s.cncftest.io/d/40/sig-mentions-categories?orgId=1).

# Description

- We're quering `gha_texts` table. It contains all 'texts' from all Kubernetes repositories.
- For more information about `gha_texts` table please check: [docs/tables/gha_texts.md](https://github.com/cncf/devstats/blob/master/docs/tables/gha_texts.md).
- We're counting distinct GitHub events (text related events: issue/PR/commit comments, PR reviews, issue/PR body texts, titles) that contain any SIG reference.
- On first panel we're groupping by category using first Postgres SQL.
- On second panel we're groupping SIG and category using second Postgres SQL.
- Regexp to match category is: `(?i)(?:^|\s)+(?:@kubernetes/sig-[\w\d-]+)(-bug|-feature-request|-pr-review|-api-review|-misc|-proposal|-design-proposal|-test-failure)s?(?:$|[^\w\d-]+)`.
- Regexp to match SIG and category is: `(?i)(?:^|\s)+((?:@kubernetes/sig-[\w\d-]+)(?:-bug|-feature-request|-pr-review|-api-review|-misc|-proposal|-design-proposal|-test-failure))s?(?:$|[^\w\d-]+)`.
- Example sig mentions: `@kubernetes/sig-node-bug`, `@Kubernetes/sig-apps-proposal`.
- We're only looking for texts created between `{{from}}` and `{{to}}` dates. Values for `from` and `to` will be replaced with final periods described later.
- We're also excluding bots activity (see [excluding bots](https://github.com/cncf/devstats/blob/master/docs/excluding_bots.md))
- Each row returns single value, so the metric type is: `multi_row_single_column`.
- First panel/first Postgres query: each row is in the format column 1: `sig_mentions_texts_cat,CatName`, column 2: `NumberOfCategoryMentions`.
- Second panel/second Postgres query: each row is in the format column 1: `sig_mentions_texts_bd,SIGName-CatName`, column 2: `NumberOfSIGCategoryMentions`.
- Both metrics use `multi_value: true`, so values are saved under different column name in a Influx DB series.

# Periods and Influx series

Metric usage is defined in metric.yaml as follows:
```
series_name_or_func: multi_row_single_column
sql: sig_mentions_cats
periods: d,w,m,q,y
aggregate: 1,7
skip: w7,m7,q7,y7
multi_value: true

(...)

series_name_or_func: multi_row_single_column
sql: sig_mentions_breakdown
periods: d,w,m,q,y
aggregate: 1,7
skip: w7,m7,q7,y7
multi_value: true
```
- It means that we should call Postgres metrics [sig_mentions_cats.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/sig_mentions_cats.sql) or [sig_mentions_breakdown.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/sig_mentions_breakdown.sql).
- We should expect multiple rows each with 2 columns: 1st defines output Influx series name, 2nd defines value.
- See [here](https://github.com/cncf/devstats/blob/master/docs/periods.md) for periods definitions.
- The final InfluxDB series name would be: `sig_mentions_texts_cat_[[period]]` or `sig_mentions_texts_bd_[[period]]`. Where `[[period]]` will be from d,w,m,q,y,d7.
- First panel: each of those series (for example `sig_mentions_texts_cat_d7`) will contain multiple columns (each column represent single category) with time series data.
- Second panel: each of those series (for example `sig_mentions_texts_bd_d7`) will contain multiple columns (each column represent single SIG-category) with time series data.
- Final querys is here: [sig_mentions_categories.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_categories.json):
  - First panel: `SELECT /^[[sigcats]]$/ FROM \"sig_mentions_texts_cat_[[period]]\" WHERE $timeFilter`.
  - Second panel: `SELECT /^[[sig]]-[[sigcats]]$/ FROM \"sig_mentions_texts_bd_[[period]]\" WHERE $timeFilter`.
- `$timeFiler` value comes from Grafana date range selector. It is handled by Grafana internally.
- `[[period]]` comes from Variable definition in dashboard JSON: [sig_mentions_categories.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_categories.json). Search for `"period"`.
- `[[sig]]` comes from Variable definition in dashboard JSON: [sig_mentions_categories.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_categories.json). Search for `"sig"`. You have to select exactly one SIG, it is used on the second panel.
- `[[sigcats]]` comes from Variable definition in dashboard JSON: [sig_mentions_categories.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_categories.json). Search for `"sigcats"`.
- Note that `[[sigcats]]` is a multi value select and reqexp part `/^[[sigcats]]$/` means that we want to see all values currently selected from the drop-down. `/^[[sig]]-[[sigcats]]$/` will select all currently selected categories values for a selected SIG.
- SIGs come from the InfluxDB tags: `SHOW TAG VALUES WITH KEY = sig_mentions_texts_name`, this tag is defined here: [idb_tags.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/idb_tags.yaml#L44).
- Categories come from the InfluxDB tags: `SHOW TAG VALUES WITH KEY = sig_mentions_texts_cat_name`, this tag is defined here: [idb_tags.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/idb_tags.yaml#L48).
- For more informations about tags check [here](https://github.com/cncf/devstats/blob/master/docs/tags.md).
- Releases comes from Grafana annotations: [sig_mentions_categories.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_categories.json). Search for `"annotations"`.
- For more details about annotations check [here](https://github.com/cncf/devstats/blob/master/docs/annotations.md).
- Project name is customized per project, it uses `[[full_name]]` template variable [definition](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_categories.json). Search for `full_name`.
- Per project variables are defined using `idb_vars`, `pdb_vars` tools, more info [here](https://github.com/cncf/devstats/blob/master/docs/vars.md).
