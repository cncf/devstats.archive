select
  'pr_auth,All' as repo,
  round(count(distinct dup_user_login) / {{n}}, 2) as authors
from
  gha_pull_requests
where
  created_at >= '{{from}}'
  and created_at < '{{to}}'
  and (lower(dup_user_login) {{exclude_bots}})
union select sub.repo,
  round(count(distinct sub.author) / {{n}}, 2) as authors
from (
  select 'pr_auth,' || pr.dup_repo_name as repo,
    pr.dup_user_login as author
  from
    gha_pull_requests pr
  where
    pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
    and (lower(pr.dup_user_login) {{exclude_bots}})
    and pr.dup_repo_name in (select repo_name from trepos)
 ) sub
group by
  sub.repo
order by
  authors desc,
  repo asc
;
