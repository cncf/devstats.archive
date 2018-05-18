select
  'iopened,All' as name,
  round(count(distinct id) / {{n}}, 2) as cnt
from
  gha_issues
where
  created_at >= '{{from}}'
  and created_at < '{{to}}'
union select 'iopened,' || r.repo_group as name,
  round(count(distinct i.id) / {{n}}, 2) as cnt
from
  gha_issues i,
  gha_repos r
where
  i.dup_repo_id = r.id
  and r.repo_group is not null
  and i.created_at >= '{{from}}'
  and i.created_at < '{{to}}'
group by
  r.repo_group
order by
  cnt desc,
  name asc
;
