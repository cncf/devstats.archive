with prs as (
  select ipr.issue_id, pr.created_at, pr.merged_at as merged_at
  from
    gha_issues_pull_requests ipr,
    gha_pull_requests pr
  where
    pr.id = ipr.pull_request_id
    and pr.merged_at is not null
    and pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
    and pr.event_id = (
      select i.event_id from gha_pull_requests i where i.id = pr.id order by i.updated_at desc limit 1
    )
), prs_groups as (
  select r.repo_group,
    ipr.issue_id,
    pr.created_at,
    pr.merged_at as merged_at
  from
    gha_issues_pull_requests ipr,
    gha_pull_requests pr,
    gha_repos r
  where
    r.id = ipr.repo_id
    and r.repo_group is not null
    and pr.id = ipr.pull_request_id
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
  select repo_group,
    extract(epoch from merged_at - created_at) / 3600 as open_to_merge
  from
    prs_groups
)
select
  'tmet;All;med,p85' as name,
  greatest(percentile_disc(0.5) within group (order by open_to_merge asc), 0) as m_o2m,
  greatest(percentile_disc(0.85) within group (order by open_to_merge asc), 0) as pc_o2m
from
  tdiffs
union select 'tmet;' || repo_group || ';med,p85' as name,
  greatest(percentile_disc(0.5) within group (order by open_to_merge asc), 0) as m_o2m,
  greatest(percentile_disc(0.85) within group (order by open_to_merge asc), 0) as pc_o2m
from
  tdiffs_groups
group by
  repo_group
order by
  name asc
;
