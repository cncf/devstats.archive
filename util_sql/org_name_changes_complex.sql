select
  org_id,
  org,
  repo,
  rid,
  date_from,
  date_to
from (
  select
    org.id as org_id,
    org.login as org,
    repo.name as repo,
    repo.id as rid,
    min(created_at) as date_from,
    max(created_at) as date_to
  from
    [githubarchive:{{period}}],
  group by
    org_id, org, repo, rid
  order by
    date_from
  )
where
  rid in (
    select
      repo.id
    from
      [githubarchive:{{period}}]
    where
      org.login = '{{org}}'
    group by
      repo.id
  )
;
