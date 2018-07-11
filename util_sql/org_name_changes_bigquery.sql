select
  org.login as org,
  repo.name as repo,
  repo.id as rid,
  min(created_at) as date_from,
  max(created_at) as date_to
from
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
where
  org.login = (
    select
      org.login
    from
      [githubarchive:month.201805]
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
