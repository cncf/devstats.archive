with issues as (
  select i.id,
    i.dup_repo_name as repo,
    i.created_at,
    i.closed_at as closed_at
  from
    gha_issues i
  where
    i.is_pull_request = false
    and i.closed_at is not null
    and i.created_at >= '{{from}}'
    and i.created_at < '{{to}}'
    and i.dup_repo_name in (select repo_name from trepos)
    and i.event_id = (
      select n.event_id from gha_issues n where n.id = i.id order by n.updated_at desc limit 1
    )
), labels as (
  select distinct issue_id,
    case dup_label_name
      when 'sig/aws' then 'sig/cloud-provider'
      when 'sig/azure' then 'sig/cloud-provider'
      when 'sig/batchd' then 'sig/cloud-provider'
      when 'sig/cloud-provider-aws' then 'sig/cloud-provider'
      when 'sig/gcp' then 'sig/cloud-provider'
      when 'sig/ibmcloud' then 'sig/cloud-provider'
      when 'sig/openstack' then 'sig/cloud-provider'
      when 'sig/vmware' then 'sig/cloud-provider'
      else dup_label_name
    end as name
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
    and substring(dup_label_name from 5) not in (
      'apimachinery', 'api-machiner', 'cloude-provider', 'nework',
      'scalability-proprosals', 'storge', 'ui-preview-reviewes',
      'cluster-fifecycle', 'rktnetes'
    )
    and dup_label_name not like '%use-only-as-a-last-resort'
    and substring(dup_label_name from 5) in (select sig_mentions_labels_name from tsig_mentions_labels)
), tdiffs as (
  select id, repo, extract(epoch from closed_at - created_at) / 3600 as age
  from
    issues
)
select
  'iage;All_All_All_All;n,m' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t
union select 'iage;' || t.repo || '_All_All_All;n,m' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t
group by
  t.repo
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
union select 'iage;' || t.repo || '_' || substring(sig.name from 5) || '_All_All;n,m' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t,
  labels sig
where
  sig.issue_id = t.id
  and sig.name like 'sig/%'
group by
  t.repo,
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
union select 'iage;' || t.repo || '_All_' || substring(kind.name from 6) || '_All;n,m' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t,
  labels kind
where
  kind.issue_id = t.id
  and kind.name like 'kind/%'
group by
  t.repo,
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
union select 'iage;' || t.repo || '_' || substring(sig.name from 5) || '_' || substring(kind.name from 6) || '_All;n,m' as name,
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
  t.repo,
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
union select 'iage;' || t.repo || '_All_All_' || substring(prio.name from 10) || ';n,m' as name,
  round(count(distinct t.id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by t.age asc) as age_median
from
  tdiffs t,
  labels prio
where
  prio.issue_id = t.id
  and prio.name like 'priority/%'
group by
  t.repo,
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
union select 'iage;' || t.repo || '_' || substring(sig.name from 5) || '_All_' || substring(prio.name from 10) || ';n,m' as name,
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
  t.repo,
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
union select 'iage;' || t.repo || '_All_' || substring(kind.name from 6) || '_' || substring(prio.name from 10) || ';n,m' as name,
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
  t.repo,
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
union select 'iage;' || t.repo || '_' || substring(sig.name from 5) || '_' || substring(kind.name from 6) || '_' || substring(prio.name from 10) || ';n,m' as name,
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
  t.repo,
  sig.name,
  kind.name,
  prio.name
order by
  age_median asc,
  name asc
;
