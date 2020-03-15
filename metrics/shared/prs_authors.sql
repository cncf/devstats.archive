select
  'pr_auth,All' as repo_group,
  round(count(distinct dup_user_login) / {{n}}, 2) as authors
from
  gha_pull_requests
where
  created_at >= '{{from}}'
  and created_at < '{{to}}'
  and (lower(dup_user_login) {{exclude_bots}})
union select sub.repo_group,
  round(count(distinct sub.author) / {{n}}, 2) as authors
from (
  select 'pr_auth,' || r.repo_group as repo_group,
    pr.dup_user_login as author
  from
    gha_repos r,
    gha_pull_requests pr
  where
    pr.dup_repo_id = r.id
    and pr.dup_repo_name = r.name
    and pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
    and (lower(pr.dup_user_login) {{exclude_bots}})
 ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group
order by
  authors desc,
  repo_group asc
;
