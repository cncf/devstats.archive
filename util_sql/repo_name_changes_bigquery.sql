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
  repo.id = (
    select
      repo.id
    from
      -- TABLE_DATE_RANGE([githubarchive:day.], TIMESTAMP('2018-01-01'), TIMESTAMP('2019-08-01'))
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
      repo.name = '{{org_repo}}'
    group by
      repo.id
    limit 1
  )
group by
  org, repo, rid, oid
order by
  date_from
;
