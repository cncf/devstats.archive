select
  'iclosed,All' as name,
  round(count(distinct id) / {{n}}, 2) as cnt
from
  gha_issues
where
  closed_at >= '{{from}}'
  and closed_at < '{{to}}'
union select 'iclosed,' || r.repo_group as name,
  round(count(distinct i.id) / {{n}}, 2) as cnt
from
  gha_issues i,
  gha_repos r
where
  i.dup_repo_id = r.id
  and r.repo_group is not null
  and i.closed_at >= '{{from}}'
  and i.closed_at < '{{to}}'
group by
  r.repo_group
order by
  cnt desc,
  name asc
;
