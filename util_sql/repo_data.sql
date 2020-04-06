#legacySQL
select
 org.login as org,
 org.id as org_id,
 repo.name as repo,
 repo.id as repo_id,
 min(created_at) as date_from,
 max(created_at) as date_to
from
  [githubarchive:month.202003],
  [githubarchive:month.202002],
  [githubarchive:month.202001],
  [githubarchive:year.2019],
  [githubarchive:year.2018],
  [githubarchive:year.2017],
  [githubarchive:year.2016],
  [githubarchive:year.2015],
  [githubarchive:year.2014]
where
  repo.name = '{{org_repo}}'
group by
  org,
  org_id,
  repo,
  repo_id
