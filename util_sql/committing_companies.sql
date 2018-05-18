select
  sub.company,
  sub.events
from (
  select aa.company_name as company,
    count(e.id) as events
  from
    gha_events e,
    gha_actors_affiliations aa
  where
    e.actor_id = aa.actor_id
    and e.type in ('PushEvent', 'PullRequestEvent')
    and e.created_at >= '{{from}}'
    and e.created_at < '{{to}}'
    and (lower(e.dup_actor_login) {{exclude_bots}})
  group by
    aa.company_name
  ) sub
order by
  sub.events desc,
  sub.company asc
;
