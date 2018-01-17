select
  sub.repo_group,
  sub.actor,
  count(distinct sub.id) as prs
from (
  select 'hist_pr_authors,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    pr.dup_actor_login as actor,
    pr.id
  from
    gha_repos r,
    gha_pull_requests pr
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = pr.event_id
  where
    {{period:pr.created_at}}
    and pr.dup_repo_id = r.id
    and pr.dup_actor_login not in ('googlebot')
    and pr.dup_actor_login not like 'k8s-%'
    and pr.dup_actor_login not like '%-bot'
    and pr.dup_actor_login not like '%-robot'
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group,
  sub.actor
having
  count(distinct sub.id) >= 3
union select 'hist_pr_authors,All' as repo_group,
  dup_actor_login as actor,
  count(distinct id) as prs
from
  gha_pull_requests
where
  {{period:created_at}}
  and dup_actor_login not in ('googlebot')
  and dup_actor_login not like 'k8s-%'
  and dup_actor_login not like '%-bot'
  and dup_actor_login not like '%-robot'
group by
  dup_actor_login
having
  count(distinct id) >= 5
order by
  prs desc,
  repo_group asc,
  actor asc
;
