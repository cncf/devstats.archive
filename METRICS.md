# Adding new metrics

To add new metric (replace `{{project}}` with kubernetes, prometheus or any other project defined in `projects.yaml`):

1) Define parameterized SQL (with `{{from}}`, `{{to}}`  and `{{n}}` params) that returns this metric data. For histogram metrics define `{{periodi:alias.date_column}}` instead.
- {{n}} is only used in aggregate periods mode and it will get value from `Number of periods` drop-down. For example for 7 days MA (moving average) it will be 7.
- Use {{period:alias.date_column}} for quick ranges based metrics, to test such metric use `PG_PASS=... ./runq ./metrics/project/filename.sql qr '1 week,,'`.
- Use (lower(actor_col) {{exclude_bots}}) to skip bot activity.
- This SQL will be automatically called on different periods by `gha2db_sync` and/or `devstats` tool.
2) Define this metric in [metrics/{{project}}/metrics.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/metrics.yaml) (file used by `gha2db_sync` tool).
- You can define this metric in `devel/test_metrics.yaml` first (and eventually in `devel/test_columns.yaml`, `devel/test_tags.yaml`) and run `devel/test_metric_sync.sh`
- Then call `sudo -u postgres psql -c 'select * from sseries_name'` to see the results.
- You need to define periods for calculations, for example m,q,y for "month, quarter and year", or h,d,w for "hour, day and week". You can use any combination of h,d,w,m,q,y. You can also use `annotations_ranges: true` for tabular tables with automatic quick ranges.
- You can define aggregate periods via `aggregate: n1,n2,n3,...`, if you don't define this, there will be one aggregation period = 1. Some aggregate combinations can be set to skip, for example you have `periods: m,q,y`, `aggregate: 1,3,7`, you want to skip >1 aggregate for y and 7 for q, then set: `skip: y3,y7,q3`.
- You need to define SQL file via `sql: filename`. It will use `metrics/{{project}}/filename.sql`.
- You need to define how to generate time series name(s) for this metrics. There are 4 options here:
- Metric can return a single row with a single value (like for instance "All PRs merged" - in that case, you can define series name inside YAML file via `series_name_or_func: your_series_name`. If metrics use more than single period, You should add `add_period_to_name: true` which will add period name to your series name (it adds _w, _d, _q etc.)
- Metric can return a single row containing multiple columns, for example, "Time opened to merged". It returns lower percentile, median and higher percentile for the time from open to merge for PRs in a given period. You should use `series_name_or_func: single_row_multi_column` in such case, and SQL should return single row, with the first column in format `series_name1,seriesn_name2,...,series_nameN` and then N value columns. The period name will be added to all N series automatically.
- Metric can return multiple rows, each containing column with series name and column with a value. Use `series_name_or_func: multi_row_single_column` in such case, for example "SIG mentions categories". Metric should return 0-N rows each one containing series name in format `prefix,series_name`, followed by value column. Series names would be in format `prefix_series_name_period`. The prefix is optional, you can use `,series_name` - it will create "series_name_period", `series_name` comes from metric so it will be normalized (like downcased, white space characters changed to underscores, UTF8 characters normalized or stripped etc.). Such series returns different row counts for different periods (for example some SIG were not mentioned in some periods). This creates data gaps.
- Metric can return multiple rows with multiple columns. You should use `series_name_or_func: multi_row_multi_column` in such case, for example, "Companies velocity", it returns multiple rows (companies) each row containing multiple company measurements (activities, authors, commits etc.). This requires special format of the first column: `prefix;series_name;measurement1,measurement2,...,measurementN`. `series_names` changes for each row, and will be normalized as if `multi_row_single_column`, the prefix is also optional as if `multi_row_single_column`. Then each row will create N series in format: `prefix_series_name_measurement1_period`, ... `prefix_series_name_measurementN_period` or if period is skipped: `series_name_measurementI_period`. Those metrics also create data gaps.
- For "histogram" metrics `histogram: true` we are putting data for last `{{period}}` using some string key instead of timestamp data. So for example simplest metric (single row, single column) means: multiple rows with hist "values", each value being "name,value" pair.
- Simplest type of histogram `series_name_or_func` is just a series name. Because we're calculating histogram for last `{{period}}` each time, given series is cleared and recalculated.
- Metric can return multiple rows with single column (which means 3 columns in histogram mode: `prefix,series_name` and then histogram value (2 columns: `name` and `value`), exactly the same as `series_name_or_func: multi_row_single_column`.
- If metrics need additional string descriptions (like when we are returning number of hours as age, and want to have nice formatted string value like "1 day 12 hours") use `desc: time_diff_as_string`.
- Metric can return multiple values in a single series (for example for SIG mentions stacking, bot commands, company stats etc), use `multi_value: true` to mark series to return multi value in a single series (instead of creating multiple series with single values). Multi values are used for stacked charts with multi value drop down to select series.
- If you want to escape value names in multi-valued series use `escape_value_name: true` in `metrics.yaml`.
3) Add test coverage in [metrics_test.go](https://github.com/cncf/devstats/blob/master/metrics_test.go) and [tests.yaml](https://github.com/cncf/devstats/blob/master/tests.yaml).
4) You need to generate data, using `PG_PASS=... ./devel/add_single_metric.sh`. If you choose to use add single metric, you need to create 2 files: `test_metrics.yaml` and `test_tags.yaml`. Those YAML files should contain only new metric related data. You may need to update `test_columns.yaml` too.
5) To test new metric on non-production database "test", use: `GHA2DB_PROJECT={{project}} ./devel/test_metric_sync.sh` script.
6) Add Grafana dashboard or row that displays this metric.
7) Export new Grafana dashboard to JSON, for example use `./devel/get_all_sqlite_jsons.sh`.
8) Create PR for the new metric.
9) Add metrics dashboard decription in this [file](https://github.com/cncf/devstats/blob/master/DASHBOARDS.md).
10) Add more detailed documentation in [dashboards documentation](https://github.com/cncf/devstats/blob/master/docs/dashboards/).

# Tags

You can define tags in [metrics/{{project}}/tags.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/tags.yaml)

# Mandatory columns

You can define mandatory columns in [metrics/{{project}}/columns.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/columns.yaml)
