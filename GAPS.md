# Filling data gaps (outdated)

If metrics create data gaps (for example returns multiple rows with different counts depending on data range), you have to add automatic filling gaps in [metrics/{{project}}gaps.yaml](https://github.com/cncf/devstats/blob/master/metrics/kubernetes/gaps.yaml) (file is used by `z2influx` tool):
- Please try to use Grafana's "null as zero" feature when stacking series instead. This gaps configuartion description is outdated.
- You need to define periods to fill gaps, they should be the same as in `metrics.yaml` definition.
- You need to define a series list to fill gaps on them. Use `series: ` to set them. It expects a list of series (YAML list).
- You need to define the same `aggregate` and `skip` values for gaps too.
- You should at least gap fill series visible on any Grafana dashboard, without doing so data display will be disturbed. If you only show subset of metrics series, you can gap fill only this subset.
- Each entry can be either a full series name, like `- my_series_d` or ...
- It can also be a series formula to create series list in this format: `"- =prefix;suffix;join_string;list1item1,list1item2,...;list2item1,list2item2,...;..."`
- Series formula allows writing a lot of series name in a shorter way. Say we have series in this form prefix_{x}_{y}_{z}_suffix and {x} can be a,b,c,d, {y} can be 1,2,3, z can be yes,no. Instead of listing all combinations prefix_a_1_yes_suffix, ..., prefix_d_3_no_suffix, which is 4 * 3 * 2 = 24 items, you can write series formula: `- =prefix;suffix;_;a,b,c,d;1,2,3;yes,no`. In this case you can see join character is _ `...;_;...`.
- If metrics uses string descriptions (like `desc: time_diff_as_string`), add `desc: true` in gaps file to clear descriptions too.
- If Metric returns multiple values in a single series and creates data gaps, then you have to list values to clear via `values: ` property, you can use series formula format to do so.
