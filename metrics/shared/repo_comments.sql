select
  'rcomments,All' as repo_group,
  round(count(distinct id) / {{n}}, 2) as result
from
  gha_comments
where
  created_at >= '{{from}}'
  and created_at < '{{to}}'
  and (lower(dup_actor_login) {{exclude_bots}})
union select sub.repo_group,
  round(count(distinct sub.id) / {{n}}, 2) as result
from (
  select 'rcomments,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    t.id
  from
    gha_repos r,
    gha_comments t
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = t.event_id
  where
    r.id = t.dup_repo_id
    and t.created_at >= '{{from}}'
    and t.created_at < '{{to}}'
    and (lower(t.dup_actor_login) {{exclude_bots}})
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group
order by
  result desc,
  repo_group asc
;
