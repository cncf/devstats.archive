# SIG mentions using labels dashboard

Links:
- Postgres SQL files: [labels_sig_kind.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_sig_kind.sql), [labels_kind.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_kind.sql) and [labels_sig.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_sig.sql).
- InfluxDB series definition: [metrics.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml). Search for `labels_sig_kind`, `labels_sig` and `labels_kind`.
- Grafana dashboard JSON: [sig_mentions_using_labels.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_using_labels.json).
- User documentation: [sig_mentions_labels.md](https://github.com/cncf/devstats/blob/master/docs/dashboards/kubernetes/sig_mentions_labels.md).
- Production version: [view](https://k8s.devstats.cncf.io/d/42/sig-mentions-using-labels?orgId=1).
- Test version: [view](https://k8s.cncftest.io/d/42/sig-mentions-using-labels?orgId=1).

# Description

- We're quering `gha_issues_labels` and `gha_issues` tables.  Those tables contains issues and their labels.
- For more information about `gha_issues_labels` table please check: [docs/tables/gha_issues_labels.md](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues_labels.md).
- For more information about `gha_issues` table please check: [docs/tables/gha_issues.md](https://github.com/cncf/devstats/blob/master/docs/tables/gha_issues.md).
- We're counting distinct issues that contain specific labels for SIGs and categories/kinds.
- Issue belnogs to some `SIGNAME` SIG - when it has `sig/SIGNAME` label.
- Issue belongs to some `CAT` category/kind - when it has `kind/CAT` label.
- This dashboard shows stacked number of issues that belongs to given SIGs and categories/kinds (by using issue labels).
- First panel shows stacked chart of number of issues belonging to selected categories for a selected SIG. It stacks different categories/kinds. It uses first SQL.
- Second panel shows stacked chart of number of issues belonging to selected categories (no matter which SIG, even no SIG at all). It stacks different categories/kinds. It uses second SQL.
- Third panel shows stacked chart of number of issues belonging to a given SIGs. It stacks by SIG and displays all possible SIGs found. It uses third SQL.
- SIG list comes from values of `sig/SIG` labels, category list contains values of `kind/kind` labels.
- We're only looking for labels that have been created on the issue between `{{from}}` and `{{to}}` dates.
- Values for `from` and `to` will be replaced with final periods described later.
- Each row returns single value, so the metric type is: `multi_row_single_column`.
- First panel/first Postgres query: each row is in the format column 1: `sig_mentions_labels_sig_kind,SIG-kind`, column 2: `NumberOfSIGCategoryIssues`.
- Second panel/second Postgres query: each row is in the format column 1: `sig_mentions_labels_kind,kind`, column 2: `NumberOfCategoryIssues`.
- Thirs panel/third Postgres query: each row is in the format column 1: `sig_mentions_labels_sig,SIG`, column 2: `NumberOfSIGIssues`.
- All metrics use `multi_value: true`, so values are saved under different column name in a Influx DB series.

# Periods and Influx series

Metric usage is defined in metric.yaml as follows:
```
series_name_or_func: multi_row_single_column
sql: labels_sig
periods: d,w,m,q,y
aggregate: 1,7
skip: w7,m7,q7,y7
multi_value: true

(...)

series_name_or_func: multi_row_single_column
sql: labels_kind
periods: d,w,m,q,y
aggregate: 1,7
skip: w7,m7,q7,y7
multi_value: true

(...)

series_name_or_func: multi_row_single_column
sql: labels_sig_kind
periods: d,w,m,q,y
aggregate: 1,7
skip: w7,m7,q7,y7
multi_value: true
```
- It means that we should call Postgres metrics [labels_sig_kind.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_sig_kind.sql), [labels_kind.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_kind.sql) and [labels_sig.sql](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/labels_sig.sql).
- We should expect multiple rows each with 2 columns: 1st defines output Influx series name, 2nd defines value.
- See [here](https://github.com/cncf/devstats/blob/master/docs/periods.md) for periods definitions.
- The final InfluxDB series name would be: `sig_mentions_labels_sig_kind_[[period]]` or `sig_mentions_labels_kind_[[period]]` or `sig_mentions_labels_sig_[[period]]`. Where `[[period]]` will be from d,w,m,q,y,d7.
- First panel: each of those series (for example `sig_mentions_labels_sig_kind_q`) will contain multiple columns (each column represent single SIG-category) with quarterly time series data.
- Second panel: each of those series (for example `sig_mentions_labels_kind_w`) will contain multiple columns (each column represent single category) with weekly time series data.
- Third panel: each of those series (for example `sig_mentions_labels_sig_d7`) will contain multiple columns (each column represent single SIG) with moving average 7 days time series data.
- Final querys is here: [sig_mentions_using_labels.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_using_labels.json):
  - First panel: `SELECT /^[[sig]]-[[kinds]]$/ FROM \"sig_mentions_labels_sig_kind_[[period]]\" WHERE $timeFilter`.
  - Second panel: `SELECT /^[[kinds]]$/ FROM \"sig_mentions_labels_kind_[[period]]\" WHERE $timeFilter`.
  - Third panel: `SELECT * FROM \"sig_mentions_labels_sig_[[period]]\" WHERE $timeFilter`.
  - Third panel: We're selecting all columns, because we can only select single SIG from drop down, and there is no sense to show only one SIG on this panel.
- `$timeFiler` value comes from Grafana date range selector. It is handled by Grafana internally.
- `[[period]]` comes from Variable definition in dashboard JSON: [sig_mentions_using_labels.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_using_labels.json). Search for `"period"`.
- `[[sig]]` comes from Variable definition in dashboard JSON: [sig_mentions_using_labels.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_using_labels.json). Search for `"sig"`. You have to select exactly one SIG, it is used on the first panel.
- `[[kinds]]` comes from Variable definition in dashboard JSON: [sig_mentions_using_labels.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_using_labels.json). Search for `"kinds"`.
- Note that `[[kinds]]` is a multi value select and reqexp part `/^[[kinds]]$/` means that we want to see all values currently selected from the drop-down. `/^[[sig]]-[[kinds]]$/` will select all currently selected categories values for a selected SIG.
- SIGs come from the InfluxDB tags: `SHOW TAG VALUES WITH KEY = sig_mentions_labels_name`, this tag is defined here: [idb_tags.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/idb_tags.yaml#L52).
- Categories come from the InfluxDB tags: `SHOW TAG VALUES WITH KEY = sig_mentions_labels_kind_name`, this tag is defined here: [idb_tags.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/idb_tags.yaml#L56).
- For more informations about tags check [here](https://github.com/cncf/devstats/blob/master/docs/tags.md).
- Releases comes from Grafana annotations: [sig_mentions_using_labels.json](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_using_labels.json). Search for `"annotations"`.
- For more details about annotations check [here](https://github.com/cncf/devstats/blob/master/docs/annotations.md).
- Project name is customized per project, it uses `[[full_name]]` template variable [definition](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/sig_mentions_using_labels.json). Search for `full_name`.
- Per project variables are defined using `idb_vars`, `pdb_vars` tools, more info [here](https://github.com/cncf/devstats/blob/master/docs/vars.md).
