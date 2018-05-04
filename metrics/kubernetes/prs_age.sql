with prs as (
  select pr.id, pr.created_at, pr.merged_at
  from
    gha_pull_requests pr
  where
    pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
    and pr.event_id = (
      select i.event_id from gha_pull_requests i where i.id = pr.id order by i.updated_at desc limit 1
    )
), prs_groups as (
  select distinct sub.repo_group,
    sub.id,
    sub.created_at,
    sub.merged_at
  from (
    select coalesce(ecf.repo_group, r.repo_group) as repo_group,
      pr.id,
      pr.created_at,
      pr.merged_at
    from
      gha_repos r,
      gha_pull_requests pr
    left join
      gha_events_commits_files ecf
    on
      ecf.event_id = pr.event_id
    where
      r.id = pr.dup_repo_id
      and pr.created_at >= '{{from}}'
      and pr.created_at < '{{to}}'
      and pr.event_id = (
        select i.event_id from gha_pull_requests i where i.id = pr.id order by i.updated_at desc limit 1
      )
    ) sub
  where
    sub.repo_group is not null
), tdiffs as (
  select id, extract(epoch from coalesce(merged_at - created_at, now() - created_at)) / 3600 as age
  from
    prs
), tdiffs_groups as (
  select repo_group, id, extract(epoch from coalesce(merged_at - created_at, now() - created_at)) / 3600 as age
  from
    prs_groups
)
select
  'prs_age;All;n,m' as name,
  round(count(distinct id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by age asc) as age_median
from
  tdiffs
union select 'prs_age;' || repo_group || ';n,m' as name,
  round(count(distinct id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by age asc) as age_median
from
  tdiffs_groups
group by
  repo_group
order by
  num desc,
  name asc
;
