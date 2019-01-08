select
  a.login as github_login,
  a.name as name,
  aa.company_name,
  aa.dt_from as date_from,
  aa.dt_to as date_to
from
  gha_actors_affiliations aa,
  gha_actors a
where
  a.id = aa.actor_id
  and aa.actor_id in (
    select distinct actor_id
    from
      gha_commits
    where
      (lower(dup_actor_login) {{exclude_bots}})
    union select distinct author_id
    from
      gha_commits
    where
      (lower(dup_author_login) {{exclude_bots}})
    union select distinct committer_id
    from
      gha_commits
    where
      (lower(dup_committer_login) {{exclude_bots}})
  )
;
