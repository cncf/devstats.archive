select
  sub.repo_group,
  sub.company,
  count(distinct sub.id) as prs
from (
  select 'hpr_comps,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
    a.company_name as company,
    pr.id
  from
    gha_repos r,
    gha_actors_affiliations a,
    gha_pull_requests pr
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = pr.event_id
  where
    pr.dup_actor_id = a.actor_id
    and a.dt_from <= pr.created_at
    and a.dt_to > pr.created_at
    and {{period:pr.created_at}}
    and pr.dup_repo_id = r.id
    and pr.dup_type = 'PullRequestEvent'
    and pr.state = 'open'
    and (lower(pr.dup_actor_login) {{exclude_bots}})
    and a.company_name != ''
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group,
  sub.company
having
  count(distinct sub.id) >= 1
union select 'hpr_comps,All' as repo_group,
  a.company_name as company,
  count(distinct pr.id) as prs
from
  gha_pull_requests pr,
  gha_actors_affiliations a
where
  pr.dup_actor_id = a.actor_id
  and a.dt_from <= pr.created_at
  and a.dt_to > pr.created_at
  and {{period:pr.created_at}}
  and dup_type = 'PullRequestEvent'
  and state = 'open'
  and (lower(pr.dup_actor_login) {{exclude_bots}})
  and a.company_name != ''
group by
  a.company_name
having
  count(distinct pr.id) >= 1
order by
  prs desc,
  repo_group asc,
  company asc
;
