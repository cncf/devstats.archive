select
  'repo_comments,All' as repo_group,
  round(count(distinct id) / {{n}}, 2) as result
from
  gha_comments
where
  created_at >= '{{from}}'
  and created_at < '{{to}}'
  and dup_actor_login not in ('googlebot')
  and dup_actor_login not like 'k8s-%'
  and dup_actor_login not like '%-bot'
  and dup_actor_login not like '%-robot'
union select sub.repo_group,
  round(count(distinct sub.id) / {{n}}, 2) as result
from (
  select 'repo_comments,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    t.id
  from
    gha_repos r,
    gha_comments t
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = t.event_id
  where
    r.id = t.dup_repo_id
    and t.created_at >= '{{from}}'
    and t.created_at < '{{to}}'
    and t.dup_actor_login not in ('googlebot')
    and t.dup_actor_login not like 'k8s-%'
    and t.dup_actor_login not like '%-bot'
    and t.dup_actor_login not like '%-robot'
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group
order by
  result desc,
  repo_group asc
;
