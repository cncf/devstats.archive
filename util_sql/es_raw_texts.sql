select
  txt.event_id,
  txt.body,
  txt.created_at,
  txt.type,
  txt.repo_name,
  coalesce(r.org_login, ''),
  coalesce(r.repo_group, ''),
  coalesce(r.alias, ''),
  coalesce(txt.actor_login, actor.login, ''),
  coalesce(actor.name, ''),
  coalesce(actor.country_id, ''),
  coalesce(actor.sex, ''),
  actor.sex_prob,
  coalesce(actor.tz, ''),
  actor.tz_offset,
  coalesce(actor.country_name, ''),
  coalesce(actor_aff.company_name, '')
from
  gha_texts txt
left join
  gha_repos r
on
  txt.repo_id = r.id
  and txt.repo_name = r.name
left join
  gha_actors actor
on
  txt.actor_id = actor.id
left join
  gha_actors_affiliations actor_aff
on
  txt.actor_id = actor_aff.actor_id
  and actor_aff.dt_from <= txt.created_at
  and actor_aff.dt_to > txt.created_at
where
  txt.created_at >= '{{from}}'
  and txt.created_at < '{{to}}'
;

