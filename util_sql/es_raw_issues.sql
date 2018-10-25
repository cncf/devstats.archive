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
  m.number,
  coalesce(m.state, ''),
  coalesce(m.title, ''), 
-- dup_repo_id         | bigint                      |           | not null |
-- dup_repo_name       | character varying(160)      |           | not null |
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
  coalesce(usr.country_name, '')
from
  gha_issues i
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
where
  i.dup_created_at >= '{{from}}'
  and i.dup_created_at < '{{to}}'
;
