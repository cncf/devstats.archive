select
  'rcommenters,All' as repo_group,
  round(count(distinct actor_login) / {{n}}, 2) as result
from
  gha_texts
where
  created_at >= '{{from}}'
  and created_at < '{{to}}'
  and (lower(actor_login) {{exclude_bots}})
union select sub.repo_group,
  round(count(distinct sub.actor_login) / {{n}}, 2) as result
from (
  select 'rcommenters,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    t.actor_login
  from
    gha_repos r,
    gha_texts t
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = t.event_id
  where
    r.id = t.repo_id
    and r.name = t.repo_name
    and t.created_at >= '{{from}}'
    and t.created_at < '{{to}}'
    and (lower(t.actor_login) {{exclude_bots}})
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group
order by
  result desc,
  repo_group asc
;
