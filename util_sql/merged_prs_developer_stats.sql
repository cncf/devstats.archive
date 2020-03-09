select 
  'hdev_' || sub.metric || ',All_All' as metric,
  sub.author || '$$$' || sub.company as name,
  sub.value as value
from (
  select 'merged_prs' as metric,
    i.dup_user_login as author,
    coalesce(aa.company_name, '') as company,
    count(distinct i.id) as value
  from
    gha_pull_requests i
  left join
    gha_actors_affiliations aa
  on
    aa.actor_id = i.user_id
    and i.merged_at is not null
    and aa.dt_from <= i.merged_at
    and aa.dt_to > i.merged_at
  where
    {{period:i.merged_at}}
    and (lower(i.dup_user_login) {{exclude_bots}})
  group by
    i.dup_user_login,
    aa.company_name
  ) sub
where
  (sub.metric = 'events' and sub.value >= 200)
  or (sub.metric = 'active_repos' and sub.value > 2)
  or (sub.metric = 'contributions' and sub.value > 10)
  or (sub.metric = 'commit_comments' and sub.value > 10)
  or (sub.metric = 'comments' and sub.value > 10)
  or (sub.metric = 'issue_comments' and sub.value > 10)
  or (sub.metric = 'review_comments' and sub.value > 10)
  or (sub.metric in (
    'commits',
    'pushes',
    'issues',
    'prs',
    'merged_prs'
  )
)
union select 'hdev_' || sub.metric || ',' || sub.repo_group || '_All' as metric,
  sub.author || '$$$' || sub.company as name,
  sub.value as value
from (
  select 'merged_prs' as metric,
    sub.repo_group,
    sub.author,
    sub.company,
    count(distinct sub.id) as value
  from (
    select coalesce(ecf.repo_group, r.repo_group) as repo_group,
      i.dup_user_login as author,
      coalesce(aa.company_name, '') as company,
      i.id
    from
      gha_repos r,
      gha_pull_requests i
    left join
      gha_events_commits_files ecf
    on
      ecf.event_id = i.event_id
    left join
      gha_actors_affiliations aa
    on
      aa.actor_id = i.user_id
      and aa.dt_from <= i.merged_at
      and aa.dt_to > i.merged_at
    where
    i.dup_repo_name = r.name
    and i.merged_at is not null
    and i.dup_repo_id = r.id
    and {{period:i.merged_at}}
    and (lower(i.dup_user_login) {{exclude_bots}})
  ) sub
  where
    sub.repo_group is not null
  group by
    sub.repo_group,
    sub.author,
    sub.company
) sub
union select 'hdev_' || sub.metric || ',All_' || sub.country as metric,
  sub.author || '$$$' || sub.company as name,
  sub.value as value
from (
  select 'merged_prs' as metric,
    a.country_name as country,
    a.login as author,
    coalesce(aa.company_name, '') as company,
    count(distinct pr.id) as value
  from
    gha_actors a,
    gha_pull_requests pr
  left join
    gha_actors_affiliations aa
  on
    aa.actor_id = pr.user_id
    and aa.dt_from <= pr.merged_at
    and aa.dt_to > pr.merged_at
  where
    (pr.user_id = a.id or pr.dup_user_login = a.login)
    and pr.merged_at is not null
    and {{period:pr.merged_at}}
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
  group by
    a.country_name,
    a.login,
    aa.company_name
  ) sub
where
  (sub.metric = 'events' and sub.value >= 50)
  or (sub.metric = 'active_repos' and sub.value > 2)
  or (sub.metric = 'contributions' and sub.value > 10)
  or (sub.metric = 'commit_comments' and sub.value > 5)
  or (sub.metric = 'comments' and sub.value > 10)
  or (sub.metric = 'issue_comments' and sub.value > 5)
  or (sub.metric = 'review_comments' and sub.value > 5)
  or (sub.metric in (
    'commits',
    'pushes',
    'issues',
    'prs',
    'merged_prs'
  )
)
union select 'hdev_' || sub.metric || ',' || sub.repo_group || '_' || sub.country as metric,
  sub.author || '$$$' || sub.company as name,
  sub.value as value
from (
  select 'merged_prs' as metric,
    sub.repo_group,
    sub.country,
    sub.author,
    sub.company,
    count(distinct sub.id) as value
  from (
    select coalesce(ecf.repo_group, r.repo_group) as repo_group,
      a.country_name as country,
      a.login as author,
      coalesce(aa.company_name, '') as company,
      i.id
    from
      gha_actors a,
      gha_repos r,
      gha_pull_requests i
    left join
      gha_events_commits_files ecf
    on
      ecf.event_id = i.event_id
    left join
      gha_actors_affiliations aa
    on
      aa.actor_id = i.user_id
      and aa.dt_from <= i.merged_at
      and aa.dt_to > i.merged_at
    where
      i.dup_repo_name = r.name
      and i.merged_at is not null
      and i.dup_repo_id = r.id
      and (i.user_id = a.id or i.dup_user_login = a.login)
      and {{period:i.merged_at}}
      and (lower(a.login) {{exclude_bots}})
  ) sub
  where
    sub.repo_group is not null
    and sub.country is not null
  group by
    sub.repo_group,
    sub.country,
    sub.author,
    sub.company
  ) sub
where
  (sub.metric = 'events' and sub.value >= 20)
  or (sub.metric = 'active_repos' and sub.value > 2)
  or (sub.metric = 'contributions' and sub.value > 5)
  or (sub.metric = 'commit_comments' and sub.value > 5)
  or (sub.metric = 'comments' and sub.value > 5)
  or (sub.metric = 'issue_comments' and sub.value > 5)
  or (sub.metric = 'review_comments' and sub.value > 5)
  or (sub.metric in (
    'commits',
    'pushes',
    'issues',
    'prs',
    'merged_prs'
  )
)
order by
  metric asc,
  value desc,
  name asc
;
