with prs as (
  select pr.created_at, pr.merged_at
  from
    gha_pull_requests pr
  where
    pr.merged_at is not null
    and pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
    and pr.event_id = (
      select i.event_id from gha_pull_requests i where i.id = pr.id order by i.updated_at desc limit 1
    )
), prs_groups as (
  select r.repo_group,
    pr.created_at,
    pr.merged_at as merged_at
  from
    gha_pull_requests pr,
    gha_repos r
  where
    r.id = pr.dup_repo_id
    and r.repo_group is not null
    and pr.merged_at is not null
    and pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
    and pr.event_id = (
      select i.event_id from gha_pull_requests i where i.id = pr.id order by i.updated_at desc limit 1
    )
), tdiffs as (
  select extract(epoch from merged_at - created_at) / 3600 as open_to_merge
  from
    prs
), tdiffs_groups as (
  select repo_group, extract(epoch from merged_at - created_at) / 3600 as open_to_merge
  from
    prs_groups
)
select
  'open2merge;All;p15,med,p85' as name,
  percentile_disc(0.15) within group (order by open_to_merge asc) as open_to_merge_15_percentile,
  percentile_disc(0.5) within group (order by open_to_merge asc) as open_to_merge_median,
  percentile_disc(0.85) within group (order by open_to_merge asc) as open_to_merge_85_percentile
from
  tdiffs
union select 'open2merge;' || repo_group || ';p15,med,p85' as name,
  percentile_disc(0.15) within group (order by open_to_merge asc) as open_to_merge_15_percentile,
  percentile_disc(0.5) within group (order by open_to_merge asc) as open_to_merge_median,
  percentile_disc(0.85) within group (order by open_to_merge asc) as open_to_merge_85_percentile
from
  tdiffs_groups
group by
  repo_group
order by
  open_to_merge_median desc,
  name asc
;
