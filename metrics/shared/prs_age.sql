with prs as (
  select pr.id,
    pr.created_at,
    pr.merged_at
  from
    gha_pull_requests pr
  where
    pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
    and pr.event_id = (
      select i.event_id from gha_pull_requests i where i.id = pr.id order by i.updated_at desc limit 1
    )
    and (
      pr.closed_at is null
      or (
        pr.closed_at is not null
        and pr.merged_at is not null
      )
    )
), prs_groups as (
  select r.repo_group,
    pr.id,
    pr.created_at,
    pr.merged_at as merged_at
  from
    gha_pull_requests pr,
    gha_repos r
  where
    r.id = pr.dup_repo_id
    and r.name = pr.dup_repo_name
    and r.repo_group is not null
    and pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
    and pr.event_id = (
      select i.event_id from gha_pull_requests i where i.id = pr.id order by i.updated_at desc limit 1
    )
    and (
      pr.closed_at is null
      or (
        pr.closed_at is not null
        and pr.merged_at is not null
      )
    )
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
