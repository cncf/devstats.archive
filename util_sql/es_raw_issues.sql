select
  i.id,
  i.event_id,
  i.dup_created_at,
  i.created_at,
  coalesce(i.body, ''),
  i.closed_at,
  i.comments,
  i.locked,
  i.number,
  i.state,
  i.title,
  i.updated_at,
  i.is_pull_request,
  i.dup_type,
  i.dup_repo_name,
  coalesce(r.org_login, ''),
  coalesce(r.repo_group, ''),
  coalesce(r.alias, ''),
  m.number,
  coalesce(m.state, ''),
  coalesce(m.title, ''),
  coalesce(i.dupn_assignee_login, assignee.login, ''),
  coalesce(assignee.name, ''),
  coalesce(assignee.country_id, ''),
  coalesce(assignee.sex, ''),
  assignee.sex_prob,
  coalesce(assignee.tz, ''),
  assignee.tz_offset,
  coalesce(assignee.country_name, ''),
  coalesce(i.dup_actor_login, actor.login, ''),
  coalesce(actor.name, ''),
  coalesce(actor.country_id, ''),
  coalesce(actor.sex, ''),
  actor.sex_prob,
  coalesce(actor.tz, ''),
  actor.tz_offset,
  coalesce(actor.country_name, ''),
  coalesce(i.dup_user_login, usr.login, ''),
  coalesce(usr.name, ''),
  coalesce(usr.country_id, ''),
  coalesce(usr.sex, ''),
  usr.sex_prob,
  coalesce(usr.tz, ''),
  usr.tz_offset,
  coalesce(usr.country_name, ''),
  coalesce(assignee_aff.company_name, ''),
  coalesce(actor_aff.company_name, ''),
  coalesce(usr_aff.company_name, '')
from
  gha_issues i
left join
  gha_repos r
on
  i.dup_repo_id = r.id
  and i.dup_repo_name = r.name
left join
  gha_actors assignee
on
  i.assignee_id = assignee.id
left join
  gha_actors actor
on
  i.dup_actor_id = actor.id
left join
  gha_actors usr
on
  i.user_id = usr.id
left join
  gha_milestones m
on
  i.milestone_id = m.id
  and i.event_id = m.event_id
left join
  gha_actors_affiliations assignee_aff
on
  i.assignee_id = assignee_aff.actor_id
  and assignee_aff.dt_from <= i.dup_created_at
  and assignee_aff.dt_to > i.dup_created_at
left join
  gha_actors_affiliations actor_aff
on
  i.dup_actor_id = actor_aff.actor_id
  and actor_aff.dt_from <= i.dup_created_at
  and actor_aff.dt_to > i.dup_created_at
left join
  gha_actors_affiliations usr_aff
on
  i.user_id = usr_aff.actor_id
  and usr_aff.dt_from <= i.created_at
  and usr_aff.dt_to > i.created_at
where
  i.dup_created_at >= '{{from}}'
  and i.dup_created_at < '{{to}}'
;
