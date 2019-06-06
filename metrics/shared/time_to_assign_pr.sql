with prs as (
  select distinct id,
    min(created_at) over prs_timeline as created_at,
    first_value(user_id) over prs_timeline as user_id
  from
    gha_pull_requests
  where
    created_at >= '{{from}}'
    and created_at < '{{to}}'
  window
    prs_timeline as (
      partition by
        id
      order by
        updated_at,
        event_id
      range between unbounded preceding
      and current row
  )
), tdiffs as (
  select extract(epoch from pr2.updated_at - pr.created_at) / 3600 as diff,
    coalesce(ecf.repo_group, r.repo_group) as repo_group
  from
    prs pr,
    gha_repos r,
    gha_pull_requests pr2
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = pr2.event_id
  where
    pr.id = pr2.id
    and r.name = pr2.dup_repo_name
    and r.id = pr2.dup_repo_id
    and pr2.event_id in (
      select sub.event_id
      from
        gha_pull_requests sub
      where
        sub.id = pr.id
        and sub.assignee_id is not null
        and sub.dup_actor_id != pr.user_id                           -- skip actors that can sel-assign themself
        and sub.updated_at > pr.created_at + '30 seconds'::interval  -- skip automatic assignment that can happen just after the PR is created
      order by
        sub.updated_at asc
      limit 1
    )
)
select
  'prassign;All;p15,med,p85' as name,
  percentile_disc(0.15) within group (order by diff asc) as prassign_15_percentile,
  percentile_disc(0.5) within group (order by diff asc) as prassign_median,
  percentile_disc(0.85) within group (order by diff asc) as prassign_85_percentile
from
  tdiffs
union select 'prassign;' || repo_group || ';p15,med,p85' as name,
  percentile_disc(0.15) within group (order by diff asc) as prassign_15_percentile,
  percentile_disc(0.5) within group (order by diff asc) as prassign_median,
  percentile_disc(0.85) within group (order by diff asc) as prassign_85_percentile
from
  tdiffs
where
  repo_group is not null
group by
  repo_group
order by
  prassign_median desc,
  name asc
;
