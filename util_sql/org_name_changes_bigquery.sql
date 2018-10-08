select
  org.id as org_id,
  org.login as org,
  repo.name as repo,
  repo.id as rid,
  min(created_at) as date_from,
  max(created_at) as date_to
from
  [githubarchive:month.201809],
  [githubarchive:month.201808],
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
where
  org.id = (
    select
      org.id
    from
      [githubarchive:month.201809]
    where
      org.login = 'your_org_name'
    group by
      org.id
  )
group by
  org_id, org, repo, rid
order by
  date_from
;
