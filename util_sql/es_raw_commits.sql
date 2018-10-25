select 
  c.sha,
  c.event_id,
  c.author_name,
  c.message,
  c.dup_actor_login,
  c.dup_repo_name,
  c.dup_created_at,
  c.encrypted_email,
  c.author_email,
  c.committer_name,
  c.committer_email,
  c.dup_author_login,
  c.dup_committer_login,
  coalesce(r.org_login, ''),
  r.repo_group,
  r.alias,
  coalesce(a.name, ''),
  coalesce(a.country_id, ''),
  coalesce(a.sex, ''),
  a.sex_prob,
  coalesce(a.tz, ''),
  a.tz_offset,
  coalesce(a.country_name, '')
from
  gha_commits c
left join
  gha_repos r
on
  c.dup_repo_id = r.id
  and c.dup_repo_name = r.name
left join
  gha_actors a
on
  c.dup_actor_id = a.id
where
  dup_created_at >= '{{from}}'
  and dup_created_at < '{{to}}'
;
