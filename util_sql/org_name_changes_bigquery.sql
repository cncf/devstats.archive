#legacySQL
select
  org.id as org_id,
  org.login as org,
  repo.name as repo,
  repo.id as rid,
  min(created_at) as date_from,
  max(created_at) as date_to
from
  [githubarchive:month.202008],
  [githubarchive:month.202007],
  [githubarchive:month.202006],
  [githubarchive:month.202005],
  [githubarchive:month.202004],
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
  org.id = (
    select
      org.id
    from
      [githubarchive:month.202008],
      [githubarchive:month.202007],
      [githubarchive:month.202006],
      [githubarchive:month.202005],
      [githubarchive:month.202004],
      [githubarchive:month.202003],
      [githubarchive:month.202002],
      [githubarchive:month.202001]
      [githubarchive:year.2019]
    where
      org.login = '{{org}}'
    group by
      org.id
  )
group by
  org_id, org, repo, rid
order by
  date_from
;
