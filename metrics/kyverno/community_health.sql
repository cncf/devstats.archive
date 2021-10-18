select
  'chealth,' || r.alias as name,
  count(distinct i.dup_user_login) as issue_creators
from
  gha_repos r,
  gha_issues i
where
  r.alias is not null
  and r.id = i.dup_repo_id
  and r.name = i.dup_repo_name
  and not i.is_pull_request
  and i.created_at < '{{to}}'
  and (lower(i.dup_user_login) {{exclude_bots}})
 group by
  r.alias
union select 'chealth,all' as name,
  count(distinct dup_user_login) as issue_creators
from
  gha_issues
where
  not is_pull_request
  and created_at < '{{to}}'
  and (lower(dup_user_login) {{exclude_bots}})
;
