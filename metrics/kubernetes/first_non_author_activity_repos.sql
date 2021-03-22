with issues as (
  select distinct id,
    user_id,
    created_at
  from
    gha_issues
  where
    is_pull_request = true
    and created_at >= '{{from}}'
    and created_at < '{{to}}'
    and (lower(dup_user_login) {{exclude_bots}})
), prs as (
  select distinct id,
    user_id,
    created_at
  from
    gha_pull_requests
  where
    created_at >= '{{from}}'
    and created_at < '{{to}}'
    and (lower(dup_user_login) {{exclude_bots}})
), labels as (
  select distinct issue_id,
    event_id,
    label_name,
    substring(label_name from 6) as label_sub_name
  from
    gha_issues_events_labels
  where
    issue_id in (select id from issues)
    and label_name in ('kind/api-change', 'kind/bug', 'kind/feature', 'kind/design', 'kind/cleanup', 'kind/documentation', 'kind/flake', 'kind/kep')
), tdiffs as (
  select extract(epoch from i2.updated_at - i.created_at) / 3600 as diff,
    i2.dup_repo_name as repo,
    'All' as label
  from
    issues i,
    gha_issues i2
  where
    i.id = i2.id
    and (lower(i2.dup_actor_login) {{exclude_bots}})
    and i2.dup_repo_name in (select repo_name from trepos)
    and i2.created_at >= '{{from}}'
    and i2.created_at < '{{to}}'
    and i2.event_id in (
      select event_id
      from
        gha_issues sub
      where
        sub.dup_actor_id != i.user_id
        and sub.id = i.id
        and sub.created_at >= '{{from}}'
        and sub.created_at < '{{to}}'
        and sub.updated_at > i.created_at + '30 seconds'::interval
        and sub.dup_type like '%Event'
      order by
        sub.updated_at asc
      limit 1
    )
  union select extract(epoch from p2.updated_at - p.created_at) / 3600 as diff,
    p2.dup_repo_name as repo,
    'All' as label
  from
    prs p,
    gha_pull_requests p2
  where
    p.id = p2.id
    and (lower(p2.dup_actor_login) {{exclude_bots}})
    and p2.dup_repo_name in (select repo_name from trepos)
    and p2.created_at >= '{{from}}'
    and p2.created_at < '{{to}}'
    and p2.event_id in (
      select event_id
      from
        gha_pull_requests sub
      where
        sub.dup_actor_id != p.user_id
        and sub.id = p.id
        and sub.created_at >= '{{from}}'
        and sub.created_at < '{{to}}'
        and sub.updated_at > p.created_at + '30 seconds'::interval
        and sub.dup_type like '%Event'
      order by
        sub.updated_at asc
      limit 1
    )
  union select extract(epoch from i2.updated_at - i.created_at) / 3600 as diff,
    i2.dup_repo_name as repo,
    iel.label_sub_name as label
  from
    issues i,
    labels iel,
    gha_issues i2
  where
    i.id = i2.id
    and iel.event_id = i2.event_id
    and (lower(i2.dup_actor_login) {{exclude_bots}})
    and i2.dup_repo_name in (select repo_name from trepos)
    and i2.created_at >= '{{from}}'
    and i2.created_at < '{{to}}'
    and i2.event_id in (
      select event_id
      from
        gha_issues sub
      where
        sub.dup_actor_id != i.user_id
        and sub.id = i.id
        and sub.created_at >= '{{from}}'
        and sub.created_at < '{{to}}'
        and sub.updated_at > i.created_at + '30 seconds'::interval
        and sub.dup_type like '%Event'
      order by
        sub.updated_at asc
      limit 1
    )
)
select
  'non_auth;All,' || label || ';p15,med,p85' as name,
  percentile_disc(0.15) within group (order by diff asc) as non_author_15_percentile,
  percentile_disc(0.5) within group (order by diff asc) as non_author_median,
  percentile_disc(0.85) within group (order by diff asc) as non_author_85_percentile
from
  tdiffs
group by
  label
union select 'non_auth;' || repo || ',' || label || ';p15,med,p85' as name,
  percentile_disc(0.15) within group (order by diff asc) as non_author_15_percentile,
  percentile_disc(0.5) within group (order by diff asc) as non_author_median,
  percentile_disc(0.85) within group (order by diff asc) as non_author_85_percentile
from
  tdiffs
group by
  label,
  repo
order by
  non_author_median desc,
  name asc
;
