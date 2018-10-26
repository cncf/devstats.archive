select
/*
 merged_by_id          | bigint                      |           |          |
 dupn_merged_by_login  | character varying(120)      |           |          |
*/
  pr.id,
  pr.event_id,
  pr.dup_created_at,
  pr.created_at,
  coalesce(pr.body, ''),
  pr.closed_at,
  pr.comments,
  pr.locked,
  pr.number,
  pr.state,
  pr.title,
  pr.updated_at,
  pr.base_sha,
  pr.head_sha,
  pr.merged_at,
  pr.merge_commit_sha,
  pr.merged,
  pr.mergeable,
  pr.rebaseable,
  pr.mergeable_state,
  pr.review_comments,
  pr.maintainer_can_modify,
  pr.commits,
  pr.additions,
  pr.deletions,
  pr.changed_files,
  pr.dup_type,
  pr.dup_repo_name,
  coalesce(r.org_login, ''),
  coalesce(r.repo_group, ''),
  coalesce(r.alias, ''),
  m.number,
  coalesce(m.state, ''),
  coalesce(m.title, ''),
  coalesce(pr.dupn_assignee_login, assignee.login, ''),
  coalesce(assignee.name, ''),
  coalesce(assignee.country_id, ''),
  coalesce(assignee.sex, ''),
  assignee.sex_prob,
  coalesce(assignee.tz, ''),
  assignee.tz_offset,
  coalesce(assignee.country_name, ''),
  coalesce(pr.dup_actor_login, actor.login, ''),
  coalesce(actor.name, ''),
  coalesce(actor.country_id, ''),
  coalesce(actor.sex, ''),
  actor.sex_prob,
  coalesce(actor.tz, ''),
  actor.tz_offset,
  coalesce(actor.country_name, ''),
  coalesce(pr.dup_user_login, usr.login, ''),
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
  gha_pull_requests pr
left join
  gha_repos r
on
  pr.dup_repo_id = r.id
  and pr.dup_repo_name = r.name
left join
  gha_actors assignee
on
  pr.assignee_id = assignee.id
left join
  gha_actors actor
on
  pr.dup_actor_id = actor.id
left join
  gha_actors usr
on
  pr.user_id = usr.id
left join
  gha_milestones m
on
  pr.milestone_id = m.id
  and pr.event_id = m.event_id
left join
  gha_actors_affiliations assignee_aff
on
  pr.assignee_id = assignee_aff.actor_id
  and assignee_aff.dt_from <= pr.dup_created_at
  and assignee_aff.dt_to > pr.dup_created_at
left join
  gha_actors_affiliations actor_aff
on
  pr.dup_actor_id = actor_aff.actor_id
  and actor_aff.dt_from <= pr.dup_created_at
  and actor_aff.dt_to > pr.dup_created_at
left join
  gha_actors_affiliations usr_aff
on
  pr.user_id = usr_aff.actor_id
  and usr_aff.dt_from <= pr.created_at
  and usr_aff.dt_to > pr.created_at
where
  pr.dup_created_at >= '{{from}}'
  and pr.dup_created_at < '{{to}}'
;

