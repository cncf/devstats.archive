# Adding new metrics

To add new metric:

1) Define parameterized SQL (with `{{from}}` and `{{to}}` params) that returns this metric data.
- This SQL will be automatically called on different periods by `gha2db_sync` tool.
2) Define this metric in [metrics/metrics.yaml](https://github.com/cncf/gha2db/blob/master/metrics/metrics.yaml) (file used by `gha2db_sync` tool).
- You need to define periods for calculations, for example m,q,y for "month, quarter and year", or h,d,w for "hour, day and week". You can use any combination of h,d,w,m,q,y.
- You need to define SQL file via `sql: filename`. It will use `metrics/filename.sql`.
- You need to define how to generate InfluxDB series name(s) for this metrics. There are 4 options here:
- Metric can return a single row with a single value (like for instance "All PRs merged" - in that case, you can define series name inside YAML file via `series_name_or_func: your_series_name`. If metrics use more than single period, You should add `add_period_to_name: true` which will add period name to your series name (it adds _w, _d, _q etc.)
- Metric can return a single row containing multiple columns, for example, "Time opened to merged". It returns lower percentile, median and higher percentile for the time from open to merge for PRs in a given period. You should use `series_name_or_func: single_row_multi_column` in such case, and SQL should return single row, with the first column in format `series_name1,seriesn_name2,...,series_nameN` and then N value columns. The period name will be added to all N series automatically.
- Metric can return multiple rows, each containing column with series name and column with a value. Use `series_name_or_func: multi_row_single_column` in such case, for example "SIG mentions categories". Metric should return 0-N rows each one containing series name in format `prefix,series_name`, followed by value column. Series names would be in format `prefix_series_name_period`. The prefix is optional, You can use `,series_name` - it will create "series_name_period", `series_name` comes from metric so it will be normalized (like downcased, white space characters changed to underscores, UTF8 characters normalized or stripped etc.). Such series returns different row counts for different periods (for example some SIG were not mentioned in some periods). This creates data gaps.
- Metric can return multiple rows with multiple columns. You should use `series_name_or_func: multi_row_multi_column` in such case, for example, "Companies velocity", it returns multiple rows (companies) each row containing multiple company measurements (activities, authors, commits etc.). This requires special format of the first column: `prefix;series_name;measurement1,measurement2,...,measurementN`. `series_names` changes for each row, and will be normalized as if `multi_row_single_column`, the prefix is also optional as if `multi_row_single_column`. Then each row will create N series in format: `prefix_series_name_measurement1_period`, ... `prefix_series_name_measurementN_period` or if period is skipped: `series_name_measurementI_period`. Those metrics also create data gaps.
3) If metrics create data gaps (for example returns multiple rows with different counts depending on data range), you have to add automatic filling gaps in [metrics/gaps.yaml](https://github.com/cncf/gha2db/blob/master/metrics/gaps.yaml) (file is used by `z2influx` tool):
- You need to define periods to fill gaps, they should be the same as in `metrics.yaml` definition.
- You need to define a series list to fill gaps on them. Use `series: ` to set them. It expects a list of series (YAML list).
- You should at least gap fill series visible on any Grafana dashboard, without doing so data display will be disturbed. If You only show subset of metrics series, You can gap fill only this subset.
- Each entry can be either a full series name, like `- my_series_d` or...
- It can also be a series formula to create series list in this format: `"- =prefix;suffix;join_string;list1item1,list1item2,...;list2item1,list2item2,...;..."`
- Series formula allows writing a lot of series name in a shorter way. Say we have series in this form prefix_{x}_{y}_{z}_suffix and {x} can be a,b,c,d, {y} can be 1,2,3, z can be yes,no. Instead of listing all combinations prefix_a_1_yes_suffix, ..., prefix_d_3_no_suffix, which is 4 * 3 * 2 = 24 items, you can write series formula: `- =prefix;suffix;_;a,b,c,d;1,2,3;yes,no`. In this case You can see join character is _ `...;_;...`.
4) Add test coverage in [metrics_test.go](https://github.com/cncf/gha2db/blob/master/metrics_test.go).
5) Add Grafana dashboard or row that displays this metric.
6) Export new Grafana dashboard to JSON.
7) Create PR for the new metric.
8) Explain how metrics SQLs works in USAGE.md (currently this is pending for all metrics defined so far).
9) Add metrics dashboard decription in this file.
