select
  org.login as org,
  repo.name as repo,
  repo.id as rid,
  min(created_at) as date_from,
  max(created_at) as date_to
from
  [githubarchive:month.201801],
  [githubarchive:year.2017]
where
  org.login = (
    select
      org.login
    from
      [githubarchive:month.201801]
    where
      org.login = 'your_org_name'
    group by
      org.login
  )
group by
  org, repo, rid
order by
  date_from
;
