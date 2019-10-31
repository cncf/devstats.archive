select
  org.login as org,
  repo.name as repo,
  repo.id as rid,
  min(created_at) as date_from,
  max(created_at) as date_to
from (
  select * from
    [githubarchive:month.201910],
    [githubarchive:month.201909],
    [githubarchive:month.201908],
    [githubarchive:month.201907],
    [githubarchive:month.201906],
    [githubarchive:month.201905],
    [githubarchive:month.201904],
    [githubarchive:month.201903],
    [githubarchive:month.201902],
    [githubarchive:month.201901],
    [githubarchive:year.2018],
    [githubarchive:year.2017],
    [githubarchive:year.2016],
    [githubarchive:year.2015],
    [githubarchive:year.2014],
    [githubarchive:year.2013],
    [githubarchive:year.2012]
 )
where
  repo.id in (
    select
      repo.id
    from
      [githubarchive:month.201910],
      [githubarchive:month.201909],
      [githubarchive:month.201908]
    where
      repo.name like 'org_name/%'
    group by
      repo.id
  )
group by
  org, repo, rid
order by
  date_from
;
