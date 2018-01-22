select
  org.login as org,
  repo.name as repo,
  repo.id as rid,
  min(created_at) as min,
  max(created_at) as max
from
  [githubarchive:month.201801],
  [githubarchive:year.2017],
  [githubarchive:year.2016],
  [githubarchive:year.2015],
  [githubarchive:year.2014]
where
  repo.id = 26509369
group by
  org, repo, rid
order by
  org, repo, rid
;
