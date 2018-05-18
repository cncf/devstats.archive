# Annotations

- Most dashboards use Grafana's annotations query.
- For example search for `"annotations": {` [here](https://github.com/cncf/devstats/blob/master/grafana/dashboards/kubernetes/reviewers-repository-groups.json).
- It uses TSDB data from `annotations` series: `select extract(epoch from time) AS time, title as text, description as tags from sannotations where $__timeFilter(time)`.
- `$timeFilter` is managed by Grafana internally and evaluates to current dashboard date range.
- Each project's annotations are computed using data from *annotation_regexp* [definition](https://github.com/cncf/devstats/blob/master/projects.yaml) (search for `annotation_regexp:`).
- `main_repo` defines GitHub repository (project can have and usually have multiple GitHub repos) to get annotations from.
- `annotation_regexp` defines RegExp patter to fetch annotations.
- Final annotation list will be a list of tags from `main_repo` that matches `annotation_regexp`.
- Tags are processed by using [git_tags.sh](https://github.com/cncf/devstats/blob/master/git/git_tags.sh) script on a given reposiory.
- Annotations are automatically created using [annotations tool](https://github.com/cncf/devstats/blob/master/cmd/annotations/annotations.go).
- You can force regenerate annotations using `{{projectname}}/annotations.sh` script. For Kubernetes it will be [kubernetes/annotations.sh](https://github.com/cncf/devstats/blob/master/kubernetes/annotations.sh).
- You can also clear all annotations using [devel/clear_all_annotations.sh](https://github.com/cncf/devstats/blob/master/devel/clear_all_annotations.sh) script and generate all annotations using [devel/add_all_annotations.sh](https://github.com/cncf/devstats/blob/master/devel/add_all_annotations.sh) script.
- Pass `ONLY='proj1 proj2'` to limit to the selected list of projects.
- When computing annotations some special series are created:
- `sannotations` it conatins all tag names & dates matching `main_repo` and `annotation_regexp` + CNCF join date (if set, search for `join_date:` [here](https://github.com/cncf/devstats/blob/master/projects.yaml))
- Example values (for Kubernetes):
```
gha=# select * from sannotations ;
       time         | period |       title        |             description             
--------------------+--------+--------------------+-------------------------------------
2014-09-09 04:00:00 |        | v0.2               | Release Kubernetes v0.2
(...)
2016-07-01 19:00:00 |        | v1.3.0             | Kubernetes official release v1.3.0
(...)
2018-03-26 16:00:00 |        | v1.10.0            | Kubernetes official release v1.10.0
2014-06-01 00:00:00 |        | Project start date | 2014-06-01 - project starts
2016-03-10 00:00:00 |        | CNCF join date     | 2016-03-10 - joined CNCF
```
- `quick_ranges` this series contain data between proceeding annotations. For example if you have annotations for v1.0 = 2014-01-01, v2.0 = 2015-01-01 and v3.0 = 2016-01-01, it will create ranges: `v1.0 - v2.0` (2014-01-01 - 2015-01-01), `v2.0 - v3.0` (2015-01-01 - 2016-01-01), `v3.0 - now` (2016-01-01 - now).
- So if you have 10 annotations it will create `a_0_1`, `a_1_2`, `a_2_3`, .., `a_8_9`, `a_9_n`.
- It will also create special periods: last day, last week, last month, last quarter, last year, last 10 days, last decade (10 years).
- Some of those period have fixed length, not changing in time (all of then not ending now - past ones), those periods will only be calculated once and special marker will be set in the `gha_computed` table to avoid calculating them multiple times.
- This flag (skip past calculation) is the default flag, unless we're full regenerating data, search for `ctx.ResetTSDB` [here](https://github.com/cncf/devstats/blob/master/cmd/gha2db_sync/gha2db_sync.go).
- Example quick ranges (for Kubernetes):
```
gha=# select * from tquick_ranges ;
       time         |                quick_ranges_data                 | quick_ranges_suffix |  quick_ranges_name  
--------------------+--------------------------------------------------+---------------------+---------------------
2014-01-01 00:00:00 | d;1 day;;                                        | d                   | Last day
2014-01-01 01:00:00 | w;1 week;;                                       | w                   | Last week
2014-01-01 02:00:00 | d10;10 days;;                                    | d10                 | Last 10 days
2014-01-01 03:00:00 | m;1 month;;                                      | m                   | Last month
2014-01-01 04:00:00 | q;3 months;;                                     | q                   | Last quarter
2014-01-01 05:00:00 | y;1 year;;                                       | y                   | Last year
2014-01-01 06:00:00 | y10;10 years;;                                   | y10                 | Last decade
2014-01-02 03:00:00 | a_20_21;;2015-07-11 04:02:31;2015-09-25 23:41:40 | a_20_21             | v1.0.0 - v1.1.0
2014-01-02 04:00:00 | a_21_22;;2015-09-25 23:41:40;2016-03-16 22:01:03 | a_21_22             | v1.1.0 - v1.2.0
2014-01-02 05:00:00 | a_22_23;;2016-03-16 22:01:03;2016-07-01 19:19:06 | a_22_23             | v1.2.0 - v1.3.0
2014-01-02 06:00:00 | a_23_24;;2016-07-01 19:19:06;2016-09-26 18:09:47 | a_23_24             | v1.3.0 - v1.4.0
2014-01-02 07:00:00 | a_24_25;;2016-09-26 18:09:47;2016-12-12 23:29:43 | a_24_25             | v1.4.0 - v1.5.0
2014-01-02 08:00:00 | a_25_26;;2016-12-12 23:29:43;2017-03-28 16:23:06 | a_25_26             | v1.5.0 - v1.6.0
2014-01-02 09:00:00 | a_26_27;;2017-03-28 16:23:06;2017-06-29 22:53:16 | a_26_27             | v1.6.0 - v1.7.0
2014-01-02 10:00:00 | a_27_28;;2017-06-29 22:53:16;2017-09-28 22:13:57 | a_27_28             | v1.7.0 - v1.8.0
2014-01-02 11:00:00 | a_28_29;;2017-09-28 22:13:57;2017-12-15 20:53:13 | a_28_29             | v1.8.0 - v1.9.0
2014-01-02 12:00:00 | a_29_30;;2017-12-15 20:53:13;2018-03-26 16:41:58 | a_29_30             | v1.9.0 - v1.10.0
2014-01-02 13:00:00 | a_30_n;;2018-03-26 16:41:58;2018-05-18 00:00:00  | a_30_n              | v1.10.0 - now
2014-01-02 14:00:00 | c_b;;2014-06-01 00:00:00;2016-03-10 00:00:00     | c_b                 | Before joining CNCF
2014-01-02 15:00:00 | c_n;;2016-03-10 00:00:00;2018-05-18 00:00:00     | c_n                 | Since joining CNCF
```
- `gha_computed` this table hold which metrics were already computed, example values (part of Kubernetes values):
```
gha=# select * from gha_computed limit 3;
           metric             |         dt          
------------------------------+---------------------
kubernetes/hist_approvers.sql | 2014-09-09 04:10:43
kubernetes/hist_approvers.sql | 2014-09-19 21:18:55
kubernetes/hist_approvers.sql | 2014-10-15 20:29:51
```
- Key is `metric` - metric file name and `dt` that holds `date from` for calculated period. Checking and setting `computed` state happens [here](https://github.com/cncf/devstats/blob/master/cmd/calc_metric/calc_metric.go), search for `isAlreadyComputed`, `setAlreadyComputed`.
- Period calculation (this is also for charts not only histograms) is determined [here](https://github.com/cncf/devstats/blob/master/time.go), search for `ComputePeriodAtThisDate`. Possible period values are: `h,d,w,m,q,y,hN,dN,wN,mN,qN,yN,anno_x_y,anno_x_now,cncf_before,cncf_now`: h..y -mean hour..year, hN, N > 1, means some aggregation of h..y, anno_x_y (x >= 0, y > x) mean past quick range, anno_x_now (x >=0) mean last quick range.
- `main_repo` and `annotation_regexp` can be empty (like for 'All' project [here](https://github.com/cncf/devstats/blob/master/projects.yaml). Depending on CNCF join date presence you will see single annotation or none then.
