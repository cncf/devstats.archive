with prev as (
  select distinct user_id
  from
    gha_pull_requests
  where
    created_at < '{{from}}'
)
select
  'new_contrib;All;contrib,prs' as name,
  round(count(distinct user_id) / {{n}}, 2) as contributors,
  round(count(distinct id) / {{n}}, 2) as prs
from
  gha_pull_requests
where
  created_at >= '{{from}}'
  and created_at < '{{to}}'
  and user_id not in (select user_id from prev)
union select sub.name,
  round(count(distinct sub.user_id) / {{n}}, 2) as contributors,
  round(count(distinct sub.id) / {{n}}, 2) as prs
from (
    select 'new_contrib;' || pr.dup_repo_name || ';contrib,prs' as name,
    pr.user_id,
    pr.id
  from
    gha_pull_requests pr
  where
    pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
    and pr.user_id not in (select user_id from prev)
    and pr.dup_repo_name in (select repo_name from trepos)
  ) sub
group by
  sub.name
order by
  prs desc,
  name asc
;
