select
  'iclosed,All' as name,
  round(count(distinct id) / {{n}}, 2) as cnt
from
  gha_issues
where
  closed_at >= '{{from}}'
  and closed_at < '{{to}}'
  and is_pull_request = false
union select 'iclosed,' || r.repo_group as name,
  round(count(distinct i.id) / {{n}}, 2) as cnt
from
  gha_issues i,
  gha_repos r
where
  i.dup_repo_id = r.id
  and i.dup_repo_name = r.name
  -- and r.name in (select repo_name from trepos)
  and r.repo_group is not null
  and i.closed_at >= '{{from}}'
  and i.closed_at < '{{to}}'
  and is_pull_request = false
group by
  r.repo_group
union select 'prclosed,All' as name,
  round(count(distinct id) / {{n}}, 2) as cnt
from
  gha_pull_requests
where
  closed_at >= '{{from}}'
  and closed_at < '{{to}}'
union select 'prclosed,' || r.repo_group as name,
  round(count(distinct pr.id) / {{n}}, 2) as cnt
from
  gha_pull_requests pr,
  gha_repos r
where
  pr.dup_repo_id = r.id
  and pr.dup_repo_name = r.name
  -- and r.name in (select repo_name from trepos)
  and r.repo_group is not null
  and pr.closed_at >= '{{from}}'
  and pr.closed_at < '{{to}}'
group by
  r.repo_group
order by
  cnt desc,
  name asc
;
