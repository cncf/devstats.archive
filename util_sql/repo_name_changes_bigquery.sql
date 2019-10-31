#legacySQL
select
  org.login as org,
  repo.name as repo,
  repo.id as rid,
  org.id as oid,
  min(created_at) as date_from,
  max(created_at) as date_to
from
  -- TABLE_DATE_RANGE([githubarchive:day.], TIMESTAMP('2018-01-01'), TIMESTAMP('2019-08-01'))
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
where
  repo.id = (
    select
      repo.id
    from
      -- TABLE_DATE_RANGE([githubarchive:day.], TIMESTAMP('2018-01-01'), TIMESTAMP('2019-08-01'))
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
    where
      repo.name = '{{org_repo}}'
    group by
      repo.id
  )
group by
  org, repo, rid, oid
order by
  date_from
;
