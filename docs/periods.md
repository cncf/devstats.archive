# DevStats metrics periods definitions

- Periods can be: h,d,w,m,q,y which means we should calculate this SQL for every hour, day, week, month, quarter and year since start of a given project.
- That means about 34K+ hour ranges, 1400+ days, 210 weeks, 48 months, 12 quarter, 4 years (for Kubernetes project example as of Mar 2018).
- `{{from}}` and `{{to}}` will be replaced with those daily, weekly, .., yearly ranges.
- Aggregate (any positive integer) for example 1,7 means that we should calculate moving averages for 1 and 7.
- Aggregate 1 means nothing - just calculate value.
- Aggregate 7 means that we should calculate d7, w7, m7, q7 and y7 periods. d7 means that we're calculate period with 7 days length, but iterating 1 day each time. For example 1-8 May, then 2-9 May, then 3-10 May and so on.
- Skip: w7, m7, q7, y7 means that we should exclude those periods, so we will only have d7 left. That means we're calculating d,w,m,q,y,d7 periods. d7 is very useful, becasue it contains all 7 week days (so values are similar) but we're progressing one day instead of 7 days.
- d7 = '7 Days MA' = '7 days moving average'.
- h24 = '24 Hours MA' = '24 hours moving avegage'.
- Note that moving averages can give non-intuitive values, for example let's say there were 10 issues in 7 days. 7 Days MA will give you value 10/7 = 1.42857... which doesnt look like a correct Issue number. But this means avg 1.49 issue/day in 7 Days moving average period.

# DevStats metrics ranges definitions

- Ranges allow selecting date range for table based dashboards.
- There are two types or ranges:
  - `Last [range]`, where `[range]` is: day, week, month etc.
  - `[annotation1]` - `[annotation2]`, where `[annotation]` is a particular release/tag defined on the project main repo, it allows selecting ranges between one annotation and next one.
- See [this](https://github.com/cncf/devstats/blob/master/docs/annotations.md) for more informations about annotations.
