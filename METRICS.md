# Adding new metrics

To add new metric:

1) Define parameterized SQL (with `{{from}}`, `{{to}}`  and `{{n}}` params) that returns this metric data. For histogram metrics define `{{period}}` instead.
- {{n}} is only used in aggregate periods mode and it will get value from `Number of periods` drop-down. For example for 7 days MA (moving average) it will be 7.
- This SQL will be automatically called on different periods by `gha2db_sync` tool.
2) Define this metric in [metrics/metrics.yaml](https://github.com/cncf/gha2db/blob/master/metrics/metrics.yaml) (file used by `gha2db_sync` tool).
- You can define this metric in `test_metric.yaml` first (and eventually in `test_gaps.yaml`) and run `test_metric_sync.sh` and then call `influx` floowed by `use test`, `precision rfc3339`, `show series`, 'select * from series_name` to see the results.
- You need to define periods for calculations, for example m,q,y for "month, quarter and year", or h,d,w for "hour, day and week". You can use any combination of h,d,w,m,q,y.
- You can define aggregate periods via `aggregate: n1,n2,n3,...`, if You don't define this, there will be one aggregation period = 1.
- You need to define SQL file via `sql: filename`. It will use `metrics/filename.sql`.
- You need to define how to generate InfluxDB series name(s) for this metrics. There are 4 options here:
- Metric can return a single row with a single value (like for instance "All PRs merged" - in that case, you can define series name inside YAML file via `series_name_or_func: your_series_name`. If metrics use more than single period, You should add `add_period_to_name: true` which will add period name to your series name (it adds _w, _d, _q etc.)
- Metric can return a single row containing multiple columns, for example, "Time opened to merged". It returns lower percentile, median and higher percentile for the time from open to merge for PRs in a given period. You should use `series_name_or_func: single_row_multi_column` in such case, and SQL should return single row, with the first column in format `series_name1,seriesn_name2,...,series_nameN` and then N value columns. The period name will be added to all N series automatically.
- Metric can return multiple rows, each containing column with series name and column with a value. Use `series_name_or_func: multi_row_single_column` in such case, for example "SIG mentions categories". Metric should return 0-N rows each one containing series name in format `prefix,series_name`, followed by value column. Series names would be in format `prefix_series_name_period`. The prefix is optional, You can use `,series_name` - it will create "series_name_period", `series_name` comes from metric so it will be normalized (like downcased, white space characters changed to underscores, UTF8 characters normalized or stripped etc.). Such series returns different row counts for different periods (for example some SIG were not mentioned in some periods). This creates data gaps.
- Metric can return multiple rows with multiple columns. You should use `series_name_or_func: multi_row_multi_column` in such case, for example, "Companies velocity", it returns multiple rows (companies) each row containing multiple company measurements (activities, authors, commits etc.). This requires special format of the first column: `prefix;series_name;measurement1,measurement2,...,measurementN`. `series_names` changes for each row, and will be normalized as if `multi_row_single_column`, the prefix is also optional as if `multi_row_single_column`. Then each row will create N series in format: `prefix_series_name_measurement1_period`, ... `prefix_series_name_measurementN_period` or if period is skipped: `series_name_measurementI_period`. Those metrics also create data gaps.
- For "histogram" metrics `histogram: true` we are putting data for last `{{period}}` using some string key instead of timestamp data. So for example simplest metric (single row, single column) means: multiple rows with hist "values", each value being "name,value" pair.
- Simplest type of histogram `series_name_or_func` is just a InfluxDB series name. Because we're calculating histogram for last `{{period}}` each time, given series is cleared and recalculated.
- Metric can return multiple rows with single column (which means 3 columns in histogram mode: `prefix,series_name` and then histogram value (2 columns: `name` and `value`), exactly the same as `series_name_or_func: multi_row_single_column`.
3) If metrics create data gaps (for example returns multiple rows with different counts depending on data range), you have to add automatic filling gaps in [metrics/gaps.yaml](https://github.com/cncf/gha2db/blob/master/metrics/gaps.yaml) (file is used by `z2influx` tool):
- You need to define periods to fill gaps, they should be the same as in `metrics.yaml` definition.
- You need to define a series list to fill gaps on them. Use `series: ` to set them. It expects a list of series (YAML list).
- You should at least gap fill series visible on any Grafana dashboard, without doing so data display will be disturbed. If You only show subset of metrics series, You can gap fill only this subset.
- Each entry can be either a full series name, like `- my_series_d` or...
- It can also be a series formula to create series list in this format: `"- =prefix;suffix;join_string;list1item1,list1item2,...;list2item1,list2item2,...;..."`
- Series formula allows writing a lot of series name in a shorter way. Say we have series in this form prefix_{x}_{y}_{z}_suffix and {x} can be a,b,c,d, {y} can be 1,2,3, z can be yes,no. Instead of listing all combinations prefix_a_1_yes_suffix, ..., prefix_d_3_no_suffix, which is 4 * 3 * 2 = 24 items, you can write series formula: `- =prefix;suffix;_;a,b,c,d;1,2,3;yes,no`. In this case You can see join character is _ `...;_;...`.
4) Add test coverage in [metrics_test.go](https://github.com/cncf/gha2db/blob/master/metrics_test.go).
5) You need to either regenerate all InfluxDB data (it takes about 5-10 minutes) using `PG_PASS=... IDB_PASS=... ./reinit_all.sh` or use `PG_PASS=... IDB_PASS=... ./add_single_metric,sh`. If You choose to use add single metric, You need to create 3 files: `test_gaps.yaml` (if empty copy from metrics/empty.yaml), `test_annotations.yaml` (usually empty) and `test_metrics.yaml`. Those YAML files should contain only new metric related data.
6) To test new metric on non-production InfluxDB "test", use: `test_metric_sync.sh` script.
7) Add Grafana dashboard or row that displays this metric.
8) Export new Grafana dashboard to JSON.
9) Create PR for the new metric.
10) Explain how metrics SQLs works in USAGE.md (currently this is pending for all metrics defined so far).
11) Add metrics dashboard decription in this [file](https://github.com/cncf/gha2db/blob/master/DASHBOARDS.md).

# Annotations

You can define annotations in [metrics/annotations.yaml](https://github.com/cncf/gha2db/blob/master/metrics/annotations.yaml)
