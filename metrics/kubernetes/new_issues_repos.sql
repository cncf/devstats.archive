with prev as (
  select distinct user_id
  from
    gha_issues
  where
    created_at < '{{from}}'
    and is_pull_request = false
)
select
  'new_iss;All;contrib,iss' as name,
  round(count(distinct user_id) / {{n}}, 2) as contributors,
  round(count(distinct id) / {{n}}, 2) as issues
from
  gha_issues
where
  is_pull_request = false
  and created_at >= '{{from}}'
  and created_at < '{{to}}'
  and user_id not in (select user_id from prev)
union select sub.name,
  round(count(distinct sub.user_id) / {{n}}, 2) as contributors,
  round(count(distinct sub.id) / {{n}}, 2) as issues
from (
    select 'new_iss;' || i.dup_repo_name || ';contrib,iss' as name,
    i.user_id,
    i.id
  from
    gha_issues i
  where
    i.is_pull_request = false
    and i.created_at >= '{{from}}'
    and i.created_at < '{{to}}'
    and i.user_id not in (select user_id from prev)
    and i.dup_repo_name in (select repo_name from trepos)
  ) sub
where
  sub.name is not null
group by
  sub.name
order by
  issues desc,
  name asc
;
