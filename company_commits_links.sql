select distinct
  af.company_name as company,
  c.dup_{{actor}}_login as commit_{{actor}},
  'https://github.com/' || c.dup_repo_name || '/commit/' || c.sha as commit_link
from (
  select sha,
    dup_created_at,
    dup_repo_name,
    dup_actor_id as actor_id,
    author_id,
    committer_id,
    dup_actor_login,
    dup_author_login,
    dup_committer_login
  from
    gha_commits
  where
    dup_created_at >= '{{dtfrom}}'
    and dup_created_at < '{{dtto}}'
  ) c,
  gha_actors_affiliations af
where
  c.{{actor}}_id = af.actor_id
  and af.dt_from <= c.dup_created_at
  and af.dt_to > c.dup_created_at
  and af.company_name = '{{company}}'
  and (lower(c.dup_{{actor}}_login) {{exclude_bots}})
order by
  company asc,
  commit_{{actor}} asc,
  commit_link asc
;
