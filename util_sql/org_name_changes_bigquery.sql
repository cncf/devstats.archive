#legacySQL
select
  org.id as org_id,
  org.login as org,
  repo.name as repo,
  repo.id as rid,
  min(created_at) as date_from,
  max(created_at) as date_to
from
--  [githubarchive:month.202201],
  [githubarchive:month.202205],
  [githubarchive:month.202204],
  [githubarchive:month.202203],
  [githubarchive:month.202202],
  [githubarchive:month.202201],
  [githubarchive:year.2021],
  [githubarchive:year.2020],
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
--      [githubarchive:month.202201],
      [githubarchive:month.202205],
      [githubarchive:month.202204],
      [githubarchive:month.202203],
      [githubarchive:month.202202],
      [githubarchive:month.202201],
      [githubarchive:year.2021],
      [githubarchive:year.2020],
      [githubarchive:year.2019]
      [githubarchive:year.2018],
      [githubarchive:year.2017],
      [githubarchive:year.2016],
      [githubarchive:year.2015],
      [githubarchive:year.2014]
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
