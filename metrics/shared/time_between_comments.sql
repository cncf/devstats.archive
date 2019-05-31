with issues as (
  select sub.id,
    sub.repo,
    sub.diff / sub.events as diff
  from (
    select i.id,
      i.dup_repo_name as repo,
      count(e.id) as events,
      extract(epoch from max(e.created_at) - min(e.created_at)) / 3600 as diff
    from
      gha_events e,
      gha_issues i
    where
      e.type in ('IssuesEvent', 'IssueCommentEvent')
      and i.is_pull_request = false
      and i.event_id = e.id
      and i.created_at >= '{{from}}'
      and i.created_at < '{{to}}'
      and (lower(e.dup_actor_login) {{exclude_bots}})
    group by
      i.id,
      i.dup_repo_name
  ) sub
  where
    sub.events > 1
), tdiffs as (
  select diff,
    r.repo_group as repo_group
  from
    issues i,
    gha_repos r
  where
    r.name = i.repo
)
select
  'avgcommentdist;All;p15,med,p85' as name,
  percentile_disc(0.15) within group (order by diff asc) as avgcommentdist_15_percentile,
  percentile_disc(0.5) within group (order by diff asc) as avgcommentdist_median,
  percentile_disc(0.85) within group (order by diff asc) as avgcommentdist_85_percentile
from
  tdiffs
union select 'avgcommentdist;' || repo_group || ';p15,med,p85' as name,
  percentile_disc(0.15) within group (order by diff asc) as avgcommentdist_15_percentile,
  percentile_disc(0.5) within group (order by diff asc) as avgcommentdist_median,
  percentile_disc(0.85) within group (order by diff asc) as avgcommentdist_85_percentile
from
  tdiffs
where
  repo_group is not null
group by
  repo_group
order by
  avgcommentdist_median desc,
  name asc
;
