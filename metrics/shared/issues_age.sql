with issues as (
  select i.id,
    r.repo_group,
    i.created_at,
    i.closed_at as closed_at
  from
    gha_repos r,
    gha_issues i
  where
    i.is_pull_request = false
    and i.closed_at is not null
    and r.name = i.dup_repo_name
    and i.created_at >= '{{from}}'
    and i.created_at < '{{to}}'
    and i.event_id = (
      select n.event_id from gha_issues n where n.id = i.id order by n.updated_at desc limit 1
    )
), labels as (
  select distinct issue_id,
    dup_label_name as name
  from
    gha_issues_labels
  where
    dup_created_at >= '{{from}}'
    and dup_created_at < '{{to}}'
    and dup_label_name like 'priority/%'
    and issue_id in (
      select id from issues
    )
), tdiffs as (
  select id, repo_group, extract(epoch from closed_at - created_at) / 3600 as age
  from
    issues
)
select
  'iage;All_All;n,m' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t
union select 'iage;' || t.repo_group || '_All;n,m' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t
where
  t.repo_group is not null
group by
  t.repo_group
union select 'iage;All_' || substring(prio.name from 10) || ';n,m' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t,
  labels prio
where
  prio.issue_id = t.id
  and prio.name like 'priority/%'
group by
  prio.name
union select 'iage;' || t.repo_group || '_' || substring(prio.name from 10) || ';n,m' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t,
  labels prio
where
  t.repo_group is not null
  and prio.issue_id = t.id
  and prio.name like 'priority/%'
group by
  t.repo_group,
  prio.name
order by
  age_median asc,
  name asc
;
