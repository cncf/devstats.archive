select 
  distinct dup_actor_login,
  count(*) as contributions
from
  gha_events
where
  type in ('PushEvent', 'IssuesEvent', 'PullRequestEvent')
  and created_at > '{{date}}'
  and (lower(dup_actor_login) {{exclude_bots}})
  and dup_actor_login not in(
  select
    distinct dup_actor_login
  from
    gha_events
  where
    type in ('PushEvent', 'IssuesEvent', 'PullRequestEvent')
    and (lower(dup_actor_login) {{exclude_bots}})
    and created_at < '{{date}}'
  )
group by
  dup_actor_login
order by
  contributions desc,
  dup_actor_login asc
;
