with prs_latest as (
  select sub.id,
    sub.event_id,
    sub.created_at,
    sub.merged_at,
    sub.dup_repo_id,
    sub.dup_repo_name
  from (
    select id,
      event_id,
      created_at,
      merged_at,
      dup_repo_id,
      dup_repo_name,
      row_number() over (partition by id order by updated_at desc, event_id desc) as rank
    from
      gha_pull_requests
    where
      created_at >= '{{from}}'
      and created_at < '{{to}}'
      and merged_at is not null
  ) sub
  where
    sub.rank = 1
), prs as (
  select ipr.issue_id,
    pr.created_at,
    pr.merged_at
  from
    gha_issues_pull_requests ipr,
    prs_latest pr
  where
    pr.id = ipr.pull_request_id
), prs_groups as (
  select r.repo_group,
    ipr.issue_id,
    pr.created_at,
    pr.merged_at
  from
    gha_issues_pull_requests ipr,
    prs_latest pr,
    gha_repos r
  where
    r.id = ipr.repo_id
    and r.name = ipr.repo_name
    and r.id = pr.dup_repo_id
    and r.name = pr.dup_repo_name
    and r.repo_group is not null
    and pr.id = ipr.pull_request_id
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
