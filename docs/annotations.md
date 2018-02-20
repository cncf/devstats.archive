# Annotations

- Most dashboards use Grafana's annotations query.
- For example [here](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers.json#L32-L58).
- It uses InfluxDB data from `annotations` series: `SELECT title, description from annotations WHERE $timeFilter order by time asc`
- `$timeFilter` is managed by Grafana internally and evaluates to current dashboard date range.
- Each project's annotations are computed using data from [projects.yaml](https://github.com/cncf/devstats/blob/master/projects.yaml#L11-L12)
- `main_repo` defines GitHub repository (project can have and usually have multiple GitHub repos) to get annotations from
- `annotation_regexp` defines RegExp patter to fetch annotations.
- Final annotation list will be a list of tags from `main_repo` that matches `annotation_regexp`.
- Tags are processed by using GitHub API on a given reposiory.
- You need to have `/etc/github/oauth` file create don your server, this file shoudl contain OAuth token. Without this file you are limited to 60 API calls, see [GitHub info](https://developer.github.com/v3/#rate-limiting).
- You can force using unauthorized acces by setting environment variable `GHA2DB_GITHUB_OAUTH` to `-` - this is not recommended.
- Annotations are automatically created using [annotations tool](https://github.com/cncf/devstats/blob/master/cmd/annotations/annotations.go).
- You can force regenerate annotations using `{{projectname}}/annotations.sh` script. For Kubernetes it will be [kubernetes/annotations.sh](https://github.com/cncf/devstats/blob/master/kubernetes/annotations.sh).
- When computing annotations some special InfluxDB series are created:
- `annotations` it conatins all tag names & dates matching `main_repo` and `annotation_regexp` + CNCF join date (if set, check [here](https://github.com/cncf/devstats/blob/master/projects.yaml#L8))
- Example values (for Kubernetes):
```
> precision rfc3339
> select * from annotations
name: annotations
time                 description                              title
----                 -----------                              -----
2014-09-08T23:00:00Z Release Kubernetes v0.2  This commit wil v0.2
2014-09-19T17:00:00Z Rev the version to 0.3                   v0.3
2014-10-14T23:00:00Z Rev the version to 0.4                   v0.4
2014-11-17T23:00:00Z Add the 0.5 release.                     v0.5
2014-12-02T00:00:00Z Kubernetes version v0.6.0                v0.6.0
2014-12-16T00:00:00Z Kubernetes version v0.7.0                v0.7.0
2015-01-07T19:00:00Z Kubernetes version v0.8.0                v0.8.0
2015-01-21T03:00:00Z Kubernetes version v0.9.0                v0.9.0
2015-02-03T16:00:00Z Kubernetes version v0.10.0               v0.10.0
2015-02-18T05:00:00Z Kubernetes version v0.11.0               v0.11.0
2015-03-03T04:00:00Z Kubernetes version v0.12.0               v0.12.0
2015-03-16T23:00:00Z Kubernetes version v0.13.0               v0.13.0
2015-03-30T18:00:00Z Kubernetes version v0.14.0               v0.14.0
2015-04-13T21:00:00Z Kubernetes version v0.15.0               v0.15.0
2015-04-29T04:00:00Z Kubernetes version v0.16.0               v0.16.0
2015-05-12T04:00:00Z Kubernetes version v0.17.0               v0.17.0
2015-05-29T16:00:00Z Kubernetes version v0.18.0               v0.18.0
2015-06-10T16:00:00Z Kubernetes version v0.19.0               v0.19.0
2015-06-26T03:00:00Z Kubernetes version v0.20.0               v0.20.0
2015-07-07T21:00:00Z Kubernetes version v0.21.0               v0.21.0
2015-07-11T04:00:00Z Kubernetes version v1.0.0                v1.0.0
2015-09-25T23:00:00Z Kubernetes version v1.1.0                v1.1.0
2016-03-10T00:00:00Z 2016-03-10 - joined CNCF                 CNCF join date
2016-03-16T22:00:00Z Kubernetes version v1.2.0                v1.2.0
2016-07-01T19:00:00Z Kubernetes version v1.3.0                v1.3.0
2016-09-26T18:00:00Z Kubernetes version v1.4.0                v1.4.0
2016-12-12T23:00:00Z Kubernetes version v1.5.0                v1.5.0
2017-03-28T16:00:00Z Kubernetes version v1.6.0                v1.6.0
2017-06-29T22:00:00Z Kubernetes version v1.7.0 file updates   v1.7.0
2017-09-28T22:00:00Z Kubernetes version v1.8.0 file updates   v1.8.0
2017-12-14T19:00:00Z Merge pull request #57174 from liggitt/a v1.9.0
```
- `quick_ranges` this series contain data between proceeding annotations. For example if you have annotations for v1.0 = 2014-01-01, v2.0 = 2015-01-01 and v3.0 = 2016-01-01, it will create ranges: `v1.0 - v2.0` (2014-01-01 - 2015-01-01), `v2.0 - v3.0` (2015-01-01 - 2016-01-01), `v3.0 - now` (2016-01-01 - now).
- So if you have 10 annotations it will create `anno_0_1`, `anno_1_2`, `anno_2_3`, .., `anno_8_9`, `anno_9_now`.
- It will also create special periods: last day, last week, last month, last quarter, last year, last 10 days, last decade (10 years).
- Some of those period have fixed length, not changing in time (all of then not ending now - past ones), those periods will only be calculated once and special marker will be set in the `computed` series to avoid calculating them multiple times.
- This flag (skip past calculation) is the default flag, unless we're full regenerating data, see [this](https://github.com/cncf/devstats/blob/master/cmd/gha2db_sync/gha2db_sync.go#L470-L472).
- Example quick ranges (for Kubernetes):
```
> select * from quick_ranges
name: quick_ranges
time                 quick_ranges_data                                    quick_ranges_name quick_ranges_suffix value
----                 -----------------                                    ----------------- ------------------- -----
2018-02-20T00:00:00Z d;1 day;;                                            Last day          d                   0
2018-02-20T01:00:00Z w;1 week;;                                           Last week         w                   0
2018-02-20T02:00:00Z d10;10 days;;                                        Last 10 days      d10                 0
2018-02-20T03:00:00Z m;1 month;;                                          Last month        m                   0
2018-02-20T04:00:00Z q;3 months;;                                         Last quarter      q                   0
2018-02-20T05:00:00Z y;1 year;;                                           Last year         y                   0
2018-02-20T06:00:00Z y10;10 years;;                                       Last decade       y10                 0
2018-02-20T07:00:00Z anno_0_1;;2014-09-08 23:21:36;2014-09-19 17:11:03    v0.2 - v0.3       anno_0_1            0
2018-02-20T08:00:00Z anno_1_2;;2014-09-19 17:11:03;2014-10-14 23:46:22    v0.3 - v0.4       anno_1_2            0
2018-02-20T09:00:00Z anno_2_3;;2014-10-14 23:46:22;2014-11-17 23:01:09    v0.4 - v0.5       anno_2_3            0
2018-02-20T10:00:00Z anno_3_4;;2014-11-17 23:01:09;2014-12-02 00:26:48    v0.5 - v0.6.0     anno_3_4            0
2018-02-20T11:00:00Z anno_4_5;;2014-12-02 00:26:48;2014-12-16 00:57:39    v0.6.0 - v0.7.0   anno_4_5            0
2018-02-20T12:00:00Z anno_5_6;;2014-12-16 00:57:39;2015-01-07 19:22:53    v0.7.0 - v0.8.0   anno_5_6            0
2018-02-20T13:00:00Z anno_6_7;;2015-01-07 19:22:53;2015-01-21 03:50:24    v0.8.0 - v0.9.0   anno_6_7            0
2018-02-20T14:00:00Z anno_7_8;;2015-01-21 03:50:24;2015-02-03 16:30:13    v0.9.0 - v0.10.0  anno_7_8            0
2018-02-20T15:00:00Z anno_8_9;;2015-02-03 16:30:13;2015-02-18 05:15:37    v0.10.0 - v0.11.0 anno_8_9            0
2018-02-20T16:00:00Z anno_9_10;;2015-02-18 05:15:37;2015-03-03 04:04:24   v0.11.0 - v0.12.0 anno_9_10           0
2018-02-20T17:00:00Z anno_10_11;;2015-03-03 04:04:24;2015-03-16 23:31:03  v0.12.0 - v0.13.0 anno_10_11          0
2018-02-20T18:00:00Z anno_11_12;;2015-03-16 23:31:03;2015-03-30 18:02:57  v0.13.0 - v0.14.0 anno_11_12          0
2018-02-20T19:00:00Z anno_12_13;;2015-03-30 18:02:57;2015-04-13 21:08:45  v0.14.0 - v0.15.0 anno_12_13          0
2018-02-20T20:00:00Z anno_13_14;;2015-04-13 21:08:45;2015-04-29 04:20:12  v0.15.0 - v0.16.0 anno_13_14          0
2018-02-20T21:00:00Z anno_14_15;;2015-04-29 04:20:12;2015-05-12 04:43:34  v0.16.0 - v0.17.0 anno_14_15          0
2018-02-20T22:00:00Z anno_15_16;;2015-05-12 04:43:34;2015-05-29 16:41:41  v0.17.0 - v0.18.0 anno_15_16          0
2018-02-20T23:00:00Z anno_16_17;;2015-05-29 16:41:41;2015-06-10 16:25:31  v0.18.0 - v0.19.0 anno_16_17          0
2018-02-21T00:00:00Z anno_17_18;;2015-06-10 16:25:31;2015-06-26 03:08:58  v0.19.0 - v0.20.0 anno_17_18          0
2018-02-21T01:00:00Z anno_18_19;;2015-06-26 03:08:58;2015-07-07 21:56:55  v0.20.0 - v0.21.0 anno_18_19          0
2018-02-21T02:00:00Z anno_19_20;;2015-07-07 21:56:55;2015-07-11 04:01:34  v0.21.0 - v1.0.0  anno_19_20          0
2018-02-21T03:00:00Z anno_20_21;;2015-07-11 04:01:34;2015-09-25 23:40:56  v1.0.0 - v1.1.0   anno_20_21          0
2018-02-21T04:00:00Z anno_21_22;;2015-09-25 23:40:56;2016-03-16 22:01:03  v1.1.0 - v1.2.0   anno_21_22          0
2018-02-21T05:00:00Z anno_22_23;;2016-03-16 22:01:03;2016-07-01 19:19:06  v1.2.0 - v1.3.0   anno_22_23          0
2018-02-21T06:00:00Z anno_23_24;;2016-07-01 19:19:06;2016-09-26 18:09:47  v1.3.0 - v1.4.0   anno_23_24          0
2018-02-21T07:00:00Z anno_24_25;;2016-09-26 18:09:47;2016-12-12 23:29:43  v1.4.0 - v1.5.0   anno_24_25          0
2018-02-21T08:00:00Z anno_25_26;;2016-12-12 23:29:43;2017-03-28 16:23:06  v1.5.0 - v1.6.0   anno_25_26          0
2018-02-21T09:00:00Z anno_26_27;;2017-03-28 16:23:06;2017-06-29 22:53:16  v1.6.0 - v1.7.0   anno_26_27          0
2018-02-21T10:00:00Z anno_27_28;;2017-06-29 22:53:16;2017-09-28 22:13:57  v1.7.0 - v1.8.0   anno_27_28          0
2018-02-21T11:00:00Z anno_28_29;;2017-09-28 22:13:57;2017-12-14 19:20:37  v1.8.0 - v1.9.0   anno_28_29          0
2018-02-21T12:00:00Z anno_29_now;;2017-12-14 19:20:37;2018-02-21 00:00:00 v1.9.0 - now      anno_29_now         0
```
- `computed` this series hold which metrics were already computed, example values (part of Kubernetes values):
```
> select * from computed
name: computed
time                 computed_from       computed_key                           value
----                 -------------       ------------                           -----
2014-09-08T23:00:00Z 2014-09-08 23:21:36 kubernetes/hist_approvers.sql          0
2014-09-08T23:00:00Z 2014-09-08 23:21:36 kubernetes/project_stats.sql           0
2014-09-08T23:00:00Z 2014-09-08 23:21:36 kubernetes/project_developer_stats.sql 0
2014-09-08T23:00:00Z 2014-09-08 23:21:36 kubernetes/project_company_stats.sql   0
2014-09-08T23:00:00Z 2014-09-08 23:21:36 kubernetes/pr_workload_table.sql       0
```
- Key is `computed_key` - metric file name and `computed_from` that holds `date from` for calculated period. Checking and setting `computed` state happens [here](https://github.com/cncf/devstats/blob/master/cmd/db2influx/db2influx.go#L310-L346).
- Logic to decide when we can skip calculations is [here](https://github.com/cncf/devstats/blob/master/cmd/db2influx/db2influx.go#L387), [here](https://github.com/cncf/devstats/blob/master/cmd/db2influx/db2influx.go#L398) and [here](https://github.com/cncf/devstats/blob/master/cmd/db2influx/db2influx.go#L585).
- Period calculation (this is also for charts not only histograms) is determined [here](https://github.com/cncf/devstats/blob/master/time.go#L44). Possible period values are: `h,d,w,m,q,y,hN,dN,wN,mN,qN,yN,anno_x_y,anno_x_now`: h..y -mean hour..year, hN, N > 1, means some aggregation of h..y, anno_x_y (x >= 0, y > x) mean past quick range, anno_x_now (x >=0) mean last quick range.
- You can use: `influx -host 172.17.0.1 -username gha_admin -password pwd -database gha` to access Kubernetes InfluxDB to see those values: `precision rfc3339`, `select * from {{seriesname}}`, `{{seriesname}}` being: `quick_ranges`, `computed`, `annotations`.
- `main_repo` and `annotation_regexp` can be empty (like for 'All' project [here](https://github.com/cncf/devstats/blob/master/projects.yaml#L202-L207). Depending on CNCF join date presence you will see single annotation or none then.
