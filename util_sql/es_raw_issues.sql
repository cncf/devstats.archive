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
-- milestone_id        | bigint                      |           |          |
-- user_id             | bigint                      |           | not null |
-- dup_actor_id        | bigint                      |           | not null |
-- dup_actor_login     | character varying(120)      |           | not null |
-- dup_repo_id         | bigint                      |           | not null |
-- dup_repo_name       | character varying(160)      |           | not null |
-- dup_user_login      | character varying(120)      |           | not null |
  coalesce(dupn_assignee_login, assignee.login, ''),
  coalesce(assignee.name, ''),
  coalesce(assignee.country_id, ''),
  coalesce(assignee.sex, ''),
  assignee.sex_prob,
  coalesce(assignee.tz, ''),
  assignee.tz_offset,
  coalesce(assignee.country_name, '')
from
  gha_issues i
left join
  gha_actors assignee
on
  i.assignee_id = assignee.id
where
  i.dup_created_at >= '{{from}}'
  and i.dup_created_at < '{{to}}'
;
