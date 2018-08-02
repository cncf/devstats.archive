select
  org.login as org,
  repo.name as repo,
  repo.id as rid,
  min(created_at) as date_from,
  max(created_at) as date_to
from (
  select * from
    [githubarchive:month.201807],
    [githubarchive:month.201806],
    [githubarchive:month.201805],
    [githubarchive:month.201804],
    [githubarchive:month.201803],
    [githubarchive:month.201802],
    [githubarchive:month.201801],
    [githubarchive:year.2017],
    [githubarchive:year.2016],
    [githubarchive:year.2015],
    [githubarchive:year.2014]
 )
where
  repo.id in (
    select
      repo.id
    from
      [githubarchive:month.201802]
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
