select
  i2.github_handle,
  string_agg(i2.email, ',') as emails,
  i2.contributions
from (
  select distinct
    i.github_handle,
    i.contributions,
    ae.email
  from (
    select a.login as github_handle,
      a.id as actor_id,
      count(distinct e.id) as contributions
    from
      gha_events e,
      gha_actors a
    where
      e.dup_actor_login = a.login
      and (lower(a.login) {{exclude_bots}})
      and e.created_at >= '{{from}}'
      and e.created_at < '{{to}}'
    group by
      a.login,
      a.id
    ) i,
    gha_actors_emails ae
  where
    ae.actor_id = i.actor_id
    and i.contributions >= {{n}}
  ) i2
group by
  i2.github_handle,
  i2.contributions
order by
  i2.contributions desc
;
