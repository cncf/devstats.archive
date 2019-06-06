with issues as (
  select i.id,
    coalesce(ecf.repo_group, r.repo_group) as repo_group,
    i.created_at,
    i.closed_at as closed_at
  from
    gha_repos r,
    gha_issues i
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = i.event_id
  where
    i.is_pull_request = false
    and i.closed_at is not null
    and r.name = i.dup_repo_name
    and r.id = i.dup_repo_id
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
    and (
      dup_label_name like 'sig/%'
      or dup_label_name like 'kind/%'
      or dup_label_name like 'priority/%'
    )
    and issue_id in (
      select id from issues
    )
), tdiffs as (
  select id, repo_group, extract(epoch from closed_at - created_at) / 3600 as age
  from
    issues
)
select
  'iage;All_All_All_All;n,m' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t
union select 'iage;' || t.repo_group || '_All_All_All;n,m' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t
where
  t.repo_group is not null
group by
  t.repo_group
union select 'iage;All_' || substring(sig.name from 5) || '_All_All;n,m' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t,
  labels sig
where
  sig.issue_id = t.id
  and sig.name like 'sig/%'
group by
  sig.name
union select 'iage;' || t.repo_group || '_' || substring(sig.name from 5) || '_All_All;n,m' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t,
  labels sig
where
  t.repo_group is not null
  and sig.issue_id = t.id
  and sig.name like 'sig/%'
group by
  t.repo_group,
  sig.name
union select 'iage;All_All_' || substring(kind.name from 6) || '_All;n,m' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t,
  labels kind
where
  kind.issue_id = t.id
  and kind.name like 'kind/%'
group by
  kind.name
union select 'iage;' || t.repo_group || '_All_' || substring(kind.name from 6) || '_All;n,m' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t,
  labels kind
where
  t.repo_group is not null
  and kind.issue_id = t.id
  and kind.name like 'kind/%'
group by
  t.repo_group,
  kind.name
union select 'iage;All_' || substring(sig.name from 5) || '_' || substring(kind.name from 6) || '_All;n,m' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t,
  labels sig,
  labels kind
where
  sig.issue_id = t.id
  and sig.name like 'sig/%'
  and kind.issue_id = t.id
  and kind.name like 'kind/%'
group by
  sig.name,
  kind.name
union select 'iage;' || t.repo_group || '_' || substring(sig.name from 5) || '_' || substring(kind.name from 6) || '_All;n,m' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t,
  labels sig,
  labels kind
where
  t.repo_group is not null
  and sig.issue_id = t.id
  and sig.name like 'sig/%'
  and kind.issue_id = t.id
  and kind.name like 'kind/%'
group by
  t.repo_group,
  sig.name,
  kind.name
union select 'iage;All_All_All_' || substring(prio.name from 10) || ';n,m' as name,
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
union select 'iage;' || t.repo_group || '_All_All_' || substring(prio.name from 10) || ';n,m' as name,
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
union select 'iage;All_' || substring(sig.name from 5) || '_All_' || substring(prio.name from 10) || ';n,m' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t,
  labels sig,
  labels prio
where
  sig.issue_id = t.id
  and sig.name like 'sig/%'
  and prio.issue_id = t.id
  and prio.name like 'priority/%'
group by
  sig.name,
  prio.name
union select 'iage;' || t.repo_group || '_' || substring(sig.name from 5) || '_All_' || substring(prio.name from 10) || ';n,m' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t,
  labels sig,
  labels prio
where
  t.repo_group is not null
  and sig.issue_id = t.id
  and sig.name like 'sig/%'
  and prio.issue_id = t.id
  and prio.name like 'priority/%'
group by
  t.repo_group,
  sig.name,
  prio.name
union select 'iage;All_All_' || substring(kind.name from 6) || '_' || substring(prio.name from 10) || ';n,m' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t,
  labels kind,
  labels prio
where
  kind.issue_id = t.id
  and kind.name like 'kind/%'
  and prio.issue_id = t.id
  and prio.name like 'priority/%'
group by
  kind.name,
  prio.name
union select 'iage;' || t.repo_group || '_All_' || substring(kind.name from 6) || '_' || substring(prio.name from 10) || ';n,m' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t,
  labels kind,
  labels prio
where
  t.repo_group is not null
  and kind.issue_id = t.id
  and kind.name like 'kind/%'
  and prio.issue_id = t.id
  and prio.name like 'priority/%'
group by
  t.repo_group,
  kind.name,
  prio.name
union select 'iage;All_' || substring(sig.name from 5) || '_' || substring(kind.name from 6) || '_' || substring(prio.name from 10) || ';n,m' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t,
  labels sig,
  labels kind,
  labels prio
where
  sig.issue_id = t.id
  and sig.name like 'sig/%'
  and kind.issue_id = t.id
  and kind.name like 'kind/%'
  and prio.issue_id = t.id
  and prio.name like 'priority/%'
group by
  sig.name,
  kind.name,
  prio.name
union select 'iage;' || t.repo_group || '_' || substring(sig.name from 5) || '_' || substring(kind.name from 6) || '_' || substring(prio.name from 10) || ';n,m' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t,
  labels sig,
  labels kind,
  labels prio
where
  t.repo_group is not null
  and sig.issue_id = t.id
  and sig.name like 'sig/%'
  and kind.issue_id = t.id
  and kind.name like 'kind/%'
  and prio.issue_id = t.id
  and prio.name like 'priority/%'
group by
  t.repo_group,
  sig.name,
  kind.name,
  prio.name
order by
  age_median asc,
  name asc
;
