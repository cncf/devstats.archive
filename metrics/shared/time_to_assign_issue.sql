with issues as (
  select distinct id,
    min(created_at) over issues_timeline as created_at,
    first_value(user_id) over issues_timeline as user_id
  from
    gha_issues
  where
    is_pull_request = false
    and created_at >= '{{from}}'
    and created_at < '{{to}}'
  window
    issues_timeline as (
      partition by
        id
      order by
        updated_at,
        event_id
      range between unbounded preceding
      and current row
  )
), tdiffs as (
  select extract(epoch from i2.updated_at - i.created_at) / 3600 as diff,
    coalesce(ecf.repo_group, r.repo_group) as repo_group
  from
    issues i,
    gha_repos r,
    gha_issues i2
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = i2.event_id
  where
    i.id = i2.id
    and r.name = i2.dup_repo_name
    and i2.event_id in (
      select sub.event_id
      from
        gha_issues sub
      where
        sub.id = i.id
        and sub.assignee_id is not null
        and sub.dup_actor_id != i.user_id                           -- skip actors that can sel-assign themself
        and sub.updated_at > i.created_at + '30 seconds'::interval  -- skip automatic assignment that can happen just after the issue is created
      order by
        sub.updated_at asc
      limit 1
    )
)
select
  'iassign;All;p15,med,p85' as name,
  percentile_disc(0.15) within group (order by diff asc) as iassign_15_percentile,
  percentile_disc(0.5) within group (order by diff asc) as iassign_median,
  percentile_disc(0.85) within group (order by diff asc) as iassign_85_percentile
from
  tdiffs
union select 'iassign;' || repo_group || ';p15,med,p85' as name,
  percentile_disc(0.15) within group (order by diff asc) as iassign_15_percentile,
  percentile_disc(0.5) within group (order by diff asc) as iassign_median,
  percentile_disc(0.85) within group (order by diff asc) as iassign_85_percentile
from
  tdiffs
where
  repo_group is not null
group by
  repo_group
order by
  iassign_median desc,
  name asc
;
