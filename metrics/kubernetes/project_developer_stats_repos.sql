with commits_data as (
  select c.dup_repo_name as repo,
    c.sha,
    c.dup_actor_id as actor_id,
    c.dup_actor_login as actor_login,
    coalesce(aa.company_name, '') as company
  from
    gha_commits c
  left join
    gha_actors_affiliations aa
  on
    aa.actor_id = c.dup_actor_id
    and aa.dt_from <= c.dup_created_at
    and aa.dt_to > c.dup_created_at
  where
    {{period:c.dup_created_at}}
    and (lower(c.dup_actor_login) {{exclude_bots}})
  union select c.dup_repo_name as repo,
    c.sha,
    c.author_id as actor_id,
    c.dup_author_login as actor_login,
    coalesce(aa.company_name, '') as company
  from
    gha_commits c
  left join
    gha_actors_affiliations aa
  on
    aa.actor_id = c.author_id
    and aa.dt_from <= c.dup_created_at
    and aa.dt_to > c.dup_created_at
  where
    c.author_id is not null
    and {{period:c.dup_created_at}}
    and (lower(c.dup_author_login) {{exclude_bots}})
  union select c.dup_repo_name as repo,
    c.sha,
    c.committer_id as actor_id,
    c.dup_committer_login as actor_login,
    coalesce(aa.company_name, '') as company
  from
    gha_commits c
  left join
    gha_actors_affiliations aa
  on
    aa.actor_id = c.committer_id
    and aa.dt_from <= c.dup_created_at
    and aa.dt_to > c.dup_created_at
  where
    c.committer_id is not null
    and {{period:c.dup_created_at}}
    and (lower(c.dup_committer_login) {{exclude_bots}})
)
select 
  'hdev_' || sub.metric || ',All_All' as metric,
  sub.author || '$$$' || sub.company as name,
  sub.value as value
from (
  select 'commits' as metric,
    actor_login as author,
    company,
    count(distinct sha) as value
  from
    commits_data
  group by
    actor_login,
    company
  union select case e.type
      when 'PushEvent' then 'pushes'
      when 'PullRequestReviewCommentEvent' then 'review_comments'
      when 'IssueCommentEvent' then 'issue_comments'
      when 'CommitCommentEvent' then 'commit_comments'
    end as metric,
    e.dup_actor_login as author,
    coalesce(aa.company_name, '') as company,
    count(e.id) as value
  from
    gha_events e
  left join
    gha_actors_affiliations aa
  on
    aa.actor_id = e.actor_id
    and aa.dt_from <= e.created_at
    and aa.dt_to > e.created_at
  where
    e.type in (
      'PushEvent', 'PullRequestReviewCommentEvent',
      'IssueCommentEvent', 'CommitCommentEvent'
    )
    and {{period:e.created_at}}
    and (lower(e.dup_actor_login) {{exclude_bots}})
  group by
    e.type,
    e.dup_actor_login,
    aa.company_name
  union select 'contributions' as metric,
    e.dup_actor_login as author,
    coalesce(aa.company_name, '') as company,
    count(e.id) as value
  from
    gha_events e
  left join
    gha_actors_affiliations aa
  on
    aa.actor_id = e.actor_id
    and aa.dt_from <= e.created_at
    and aa.dt_to > e.created_at
  where
    e.type in (
      'PushEvent', 'PullRequestEvent', 'IssuesEvent',
      'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
    )
    and {{period:e.created_at}}
    and (lower(e.dup_actor_login) {{exclude_bots}})
  group by
    e.dup_actor_login,
    aa.company_name
  union select 'active_repos' as metric,
    e.dup_actor_login as author,
    coalesce(aa.company_name, '') as company,
    count(distinct e.repo_id) as value
  from
    gha_events e
  left join
    gha_actors_affiliations aa
  on
    aa.actor_id = e.actor_id
    and aa.dt_from <= e.created_at
    and aa.dt_to > e.created_at
  where
    {{period:e.created_at}}
    and (lower(e.dup_actor_login) {{exclude_bots}})
  group by
    e.dup_actor_login,
    aa.company_name
  union select 'comments' as metric,
    dup_user_login as author,
    coalesce(aa.company_name, '') as company,
    count(distinct id) as value
  from
    gha_comments c
  left join
    gha_actors_affiliations aa
  on
    aa.actor_id = c.user_id
    and aa.dt_from <= c.created_at
    and aa.dt_to > c.created_at
  where
    {{period:c.created_at}}
    and (lower(c.dup_user_login) {{exclude_bots}})
  group by
    c.dup_user_login,
    aa.company_name
  union select 'issues' as metric,
    i.dup_user_login as author,
    coalesce(aa.company_name, '') as company,
    count(distinct i.id) as value
  from
    gha_issues i
  left join
    gha_actors_affiliations aa
  on
    aa.actor_id = i.user_id
    and aa.dt_from <= i.created_at
    and aa.dt_to > i.created_at
  where
    {{period:i.created_at}}
    and i.is_pull_request = false
    and (lower(i.dup_user_login) {{exclude_bots}})
  group by
    i.dup_user_login,
    aa.company_name
  union select 'prs' as metric,
    i.dup_user_login as author,
    coalesce(aa.company_name, '') as company,
    count(distinct i.id) as value
  from
    gha_issues i
  left join
    gha_actors_affiliations aa
  on
    aa.actor_id = i.user_id
    and aa.dt_from <= i.created_at
    and aa.dt_to > i.created_at
  where
    {{period:i.created_at}}
    and i.is_pull_request = true
    and (lower(i.dup_user_login) {{exclude_bots}})
  group by
    i.dup_user_login,
    aa.company_name
  union select 'merged_prs' as metric,
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
  union select 'events' as metric,
    e.dup_actor_login as author,
    coalesce(aa.company_name, '') as company,
    count(e.id) as value
  from
    gha_events e
  left join
    gha_actors_affiliations aa
  on
    aa.actor_id = e.actor_id
    and aa.dt_from <= e.created_at
    and aa.dt_to > e.created_at
  where
    {{period:e.created_at}}
    and (lower(e.dup_actor_login) {{exclude_bots}})
  group by
    e.dup_actor_login,
    aa.company_name
  ) sub
/*where
  (sub.metric = 'events' and sub.value >= 200)
  or (sub.metric = 'active_repos' and sub.value >= 3)
  or (sub.metric = 'contributions' and sub.value >= 30)
  or (sub.metric = 'commit_comments' and sub.value >= 10)
  or (sub.metric = 'comments' and sub.value >= 20)
  or (sub.metric = 'issue_comments' and sub.value >= 20)
  or (sub.metric = 'review_comments' and sub.value >= 20)
  or (sub.metric in (
    'commits',
    'pushes',
    'issues',
    'prs',
    'merged_prs'
  ) and sub.value > 1
)*/
union select 'hdev_' || sub.metric || ',' || sub.repo || '_All' as metric,
  sub.author || '$$$' || sub.company as name,
  sub.value as value
from (
  select 'commits' as metric,
    repo,
    actor_login as author,
    company,
    count(distinct sha) as value
  from
    commits_data
  where
    repo in (select repo_name from trepos)
  group by
    repo,
    actor_login,
    company
  union select case sub.type
      when 'PushEvent' then 'pushes'
      when 'PullRequestReviewCommentEvent' then 'review_comments'
      when 'IssueCommentEvent' then 'issue_comments'
      when 'CommitCommentEvent' then 'commit_comments'
    end as metric,
    sub.repo,
    sub.author,
    sub.company,
    count(distinct sub.id) as value
  from (
    select e.dup_repo_name as repo,
      e.type,
      e.dup_actor_login as author,
      coalesce(aa.company_name, '') as company,
      e.id
    from
      gha_events e
    left join
      gha_actors_affiliations aa
    on
      aa.actor_id = e.actor_id
      and aa.dt_from <= e.created_at
      and aa.dt_to > e.created_at
    where
      e.type in (
        'PushEvent', 'PullRequestReviewCommentEvent',
        'IssueCommentEvent', 'CommitCommentEvent'
      )
      and {{period:e.created_at}}
      and (lower(e.dup_actor_login) {{exclude_bots}})
      and e.dup_repo_name in (select repo_name from trepos)
  ) sub
  group by
    sub.repo,
    sub.type,
    sub.author,
    sub.company
  union select 'contributions' as metric,
    sub.repo,
    sub.author,
    sub.company,
    count(distinct sub.id) as value
  from (
    select e.dup_repo_name as repo,
      e.dup_actor_login as author,
      coalesce(aa.company_name, '') as company,
      e.id
    from
      gha_events e
    left join
      gha_actors_affiliations aa
    on
      aa.actor_id = e.actor_id
      and aa.dt_from <= e.created_at
      and aa.dt_to > e.created_at
    where
      e.type in (
        'PushEvent', 'PullRequestEvent', 'IssuesEvent',
        'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
      )
      and {{period:e.created_at}}
      and (lower(e.dup_actor_login) {{exclude_bots}})
      and e.dup_repo_name in (select repo_name from trepos)
  ) sub
  group by
    sub.repo,
    sub.author,
    sub.company
  union select 'active_repos' as metric,
    sub.repo,
    sub.author,
    sub.company,
    count(distinct sub.repo_id) as value
  from (
    select e.dup_repo_name as repo,
      e.dup_actor_login as author,
      coalesce(aa.company_name, '') as company,
      e.repo_id
    from
      gha_events e
    left join
      gha_actors_affiliations aa
    on
      aa.actor_id = e.actor_id
      and aa.dt_from <= e.created_at
      and aa.dt_to > e.created_at
    where
      {{period:e.created_at}}
      and (lower(e.dup_actor_login) {{exclude_bots}})
      and e.dup_repo_name in (select repo_name from trepos)
  ) sub
  group by
    sub.repo,
    sub.author,
    sub.company
  union select 'comments' as metric,
    sub.repo,
    sub.author,
    sub.company,
    count(distinct sub.id) as value
  from (
    select c.dup_repo_name as repo,
      c.dup_user_login as author,
      coalesce(aa.company_name, '') as company,
      c.id
    from
      gha_comments c
    left join
      gha_actors_affiliations aa
    on
      aa.actor_id = c.user_id
      and aa.dt_from <= c.created_at
      and aa.dt_to > c.created_at
    where
      {{period:c.created_at}}
      and (lower(c.dup_user_login) {{exclude_bots}})
      and c.dup_repo_name in (select repo_name from trepos)
  ) sub
  group by
    sub.author,
    sub.company,
    sub.repo
  union select case sub.is_pull_request
      when true then 'prs'
      else 'issues'
    end as metric,
    sub.repo,
    sub.author,
    sub.company,
    count(distinct sub.id) as value
  from (
    select i.dup_repo_name as repo,
      i.dup_user_login as author,
      coalesce(aa.company_name, '') as company,
      i.id,
      i.is_pull_request
    from
      gha_issues i
    left join
      gha_actors_affiliations aa
    on
      aa.actor_id = i.user_id
      and aa.dt_from <= i.created_at
      and aa.dt_to > i.created_at
    where
    {{period:i.created_at}}
    and (lower(i.dup_user_login) {{exclude_bots}})
    and i.dup_repo_name in (select repo_name from trepos)
  ) sub
  group by
    sub.repo,
    sub.is_pull_request,
    sub.author,
    sub.company
  union select 'merged_prs' as metric,
    sub.repo,
    sub.author,
    sub.company,
    count(distinct sub.id) as value
  from (
    select i.dup_repo_name as repo,
      i.dup_user_login as author,
      coalesce(aa.company_name, '') as company,
      i.id
    from
      gha_pull_requests i
    left join
      gha_actors_affiliations aa
    on
      aa.actor_id = i.user_id
      and aa.dt_from <= i.merged_at
      and aa.dt_to > i.merged_at
    where
    i.merged_at is not null
    and {{period:i.merged_at}}
    and (lower(i.dup_user_login) {{exclude_bots}})
    and i.dup_repo_name in (select repo_name from trepos)
  ) sub
  group by
    sub.repo,
    sub.author,
    sub.company
  union select 'events' as metric,
    sub.repo,
    sub.author,
    sub.company,
    count(distinct sub.id) as value
  from (
    select e.dup_repo_name as repo,
      e.dup_actor_login as author,
      coalesce(aa.company_name, '') as company,
      e.id
    from
      gha_events e
    left join
      gha_actors_affiliations aa
    on
      aa.actor_id = e.actor_id
      and aa.dt_from <= e.created_at
      and aa.dt_to > e.created_at
    where
      {{period:e.created_at}}
      and (lower(e.dup_actor_login) {{exclude_bots}})
      and e.dup_repo_name in (select repo_name from trepos)
  ) sub
  group by
    sub.repo,
    sub.author,
    sub.company
) sub
union select 'hdev_' || sub.metric || ',All_' || sub.country as metric,
  sub.author || '$$$' || sub.company as name,
  sub.value as value
from (
  select 'commits' as metric,
    a.country_name as country,
    a.login as author,
    c.company,
    count(distinct c.sha) as value
  from
    commits_data c,
    gha_actors a
  where
    c.actor_id = a.id
    and a.country_name is not null
  group by
    a.country_name,
    a.login,
    c.company
  union select case e.type
      when 'PushEvent' then 'pushes'
      when 'PullRequestReviewCommentEvent' then 'review_comments'
      when 'IssueCommentEvent' then 'issue_comments'
      when 'CommitCommentEvent' then 'commit_comments'
    end as metric,
    a.country_name as country,
    a.login as author,
    coalesce(aa.company_name, '') as company,
    count(distinct e.id) as value
  from
    gha_actors a,
    gha_events e
  left join
    gha_actors_affiliations aa
  on
    aa.actor_id = e.actor_id
    and aa.dt_from <= e.created_at
    and aa.dt_to > e.created_at
  where
    (e.actor_id = a.id or e.dup_actor_login = a.login)
    and e.type in (
      'PushEvent', 'PullRequestReviewCommentEvent',
      'IssueCommentEvent', 'CommitCommentEvent'
    )
    and {{period:e.created_at}}
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
  group by
    e.type,
    a.country_name,
    a.login,
    aa.company_name
  union select 'contributions' as metric,
    a.country_name as country,
    a.login as author,
    coalesce(aa.company_name, '') as company,
    count(distinct e.id) as value
  from
    gha_actors a,
    gha_events e
  left join
    gha_actors_affiliations aa
  on
    aa.actor_id = e.actor_id
    and aa.dt_from <= e.created_at
    and aa.dt_to > e.created_at
  where
    (e.actor_id = a.id or e.dup_actor_login = a.login)
    and e.type in (
      'PushEvent', 'PullRequestEvent', 'IssuesEvent',
      'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
    )
    and {{period:e.created_at}}
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
  group by
    a.country_name,
    a.login,
    aa.company_name
  union select 'active_repos' as metric,
    a.country_name as country,
    a.login as author,
    coalesce(aa.company_name, '') as company,
    count(distinct e.repo_id) as value
  from
    gha_actors a,
    gha_events e
  left join
    gha_actors_affiliations aa
  on
    aa.actor_id = e.actor_id
    and aa.dt_from <= e.created_at
    and aa.dt_to > e.created_at
  where
    (e.actor_id = a.id or e.dup_actor_login = a.login)
    and {{period:e.created_at}}
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
  group by
    a.country_name,
    a.login,
    aa.company_name
  union select 'comments' as metric,
    a.country_name as country,
    a.login as author,
    coalesce(aa.company_name, '') as company,
    count(distinct c.id) as value
  from
    gha_actors a,
    gha_comments c
  left join
    gha_actors_affiliations aa
  on
    aa.actor_id = c.user_id
    and aa.dt_from <= c.created_at
    and aa.dt_to > c.created_at
  where
    (c.user_id = a.id or c.dup_user_login = a.login)
    and {{period:c.created_at}}
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
  group by
    a.country_name,
    a.login,
    aa.company_name
  union select 'issues' as metric,
    a.country_name as country,
    a.login as author,
    coalesce(aa.company_name, '') as company,
    count(distinct i.id) as value
  from
    gha_actors a,
    gha_issues i
  left join
    gha_actors_affiliations aa
  on
    aa.actor_id = i.user_id
    and aa.dt_from <= i.created_at
    and aa.dt_to > i.created_at
  where
    (i.user_id = a.id or i.dup_user_login = a.login)
    and {{period:i.created_at}}
    and i.is_pull_request = false
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
  group by
    a.country_name,
    a.login,
    aa.company_name
  union select 'prs' as metric,
    a.country_name as country,
    a.login as author,
    coalesce(aa.company_name, '') as company,
    count(distinct pr.id) as value
  from
    gha_actors a,
    gha_issues pr
  left join
    gha_actors_affiliations aa
  on
    aa.actor_id = pr.user_id
    and aa.dt_from <= pr.created_at
    and aa.dt_to > pr.created_at
  where
    (pr.user_id = a.id or pr.dup_user_login = a.login)
    and {{period:pr.created_at}}
    and pr.is_pull_request = true
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
  group by
    a.country_name,
    a.login,
    aa.company_name
  union select 'merged_prs' as metric,
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
  union select 'events' as metric,
    a.country_name as country,
    a.login as author,
    coalesce(aa.company_name, '') as company,
    count(distinct e.id) as value
  from
    gha_actors a,
    gha_events e
  left join
    gha_actors_affiliations aa
  on
    aa.actor_id = e.actor_id
    and aa.dt_from <= e.created_at
    and aa.dt_to > e.created_at
  where
    (e.actor_id = a.id or e.dup_actor_login = a.login)
    and {{period:e.created_at}}
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
  group by
    a.country_name,
    a.login,
    aa.company_name
  ) sub
/*where
  (sub.metric = 'events' and sub.value >= 100)
  or (sub.metric = 'active_repos' and sub.value >= 3)
  or (sub.metric = 'contributions' and sub.value >= 15)
  or (sub.metric = 'commit_comments' and sub.value >= 5)
  or (sub.metric = 'comments' and sub.value >= 15)
  or (sub.metric = 'issue_comments' and sub.value >= 10)
  or (sub.metric = 'review_comments' and sub.value >= 10)
  or (sub.metric in (
    'commits',
    'pushes',
    'issues',
    'prs',
    'merged_prs'
  ) and sub.value > 1
)*/
union select 'hdev_' || sub.metric || ',' || sub.repo || '_' || sub.country as metric,
  sub.author || '$$$' || sub.company as name,
  sub.value as value
from (
  select 'commits' as metric,
    c.repo,
    a.country_name as country,
    a.login as author,
    c.company,
    count(distinct c.sha) as value
  from
    commits_data c,
    gha_actors a
  where
    c.actor_id = a.id
    and a.country_name is not null
    and c.repo in (select repo_name from trepos)
  group by
    c.repo,
    a.country_name,
    a.login,
    c.company
  union select case sub.type
      when 'PushEvent' then 'pushes'
      when 'PullRequestReviewCommentEvent' then 'review_comments'
      when 'IssueCommentEvent' then 'issue_comments'
      when 'CommitCommentEvent' then 'commit_comments'
    end as metric,
    sub.repo,
    sub.country,
    sub.author,
    sub.company,
    count(distinct sub.id) as value
  from (
    select e.dup_repo_name as repo,
      e.type,
      a.country_name as country,
      a.login as author,
      coalesce(aa.company_name, '') as company,
      e.id
    from
      gha_actors a,
      gha_events e
    left join
      gha_actors_affiliations aa
    on
      aa.actor_id = e.actor_id
      and aa.dt_from <= e.created_at
      and aa.dt_to > e.created_at
    where
      (e.actor_id = a.id or e.dup_actor_login = a.login)
      and e.type in (
        'PushEvent', 'PullRequestReviewCommentEvent',
        'IssueCommentEvent', 'CommitCommentEvent'
      )
      and {{period:e.created_at}}
      and (lower(a.login) {{exclude_bots}})
      and e.dup_repo_name in (select repo_name from trepos)
  ) sub
  where
    sub.country is not null
  group by
    sub.repo,
    sub.type,
    sub.country,
    sub.author,
    sub.company
  union select 'contributions' as metric,
    sub.repo,
    sub.country,
    sub.author,
    sub.company,
    count(distinct sub.id) as value
  from (
    select e.dup_repo_name as repo,
      a.country_name as country,
      a.login as author,
      coalesce(aa.company_name, '') as company,
      e.id
    from
      gha_actors a,
      gha_events e
    left join
      gha_actors_affiliations aa
    on
      aa.actor_id = e.actor_id
      and aa.dt_from <= e.created_at
      and aa.dt_to > e.created_at
    where
      (e.actor_id = a.id or e.dup_actor_login = a.login)
      and e.type in (
        'PushEvent', 'PullRequestEvent', 'IssuesEvent',
        'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
      )
      and {{period:e.created_at}}
      and (lower(a.login) {{exclude_bots}})
      and e.dup_repo_name in (select repo_name from trepos)
  ) sub
  where
    sub.country is not null
  group by
    sub.repo,
    sub.country,
    sub.author,
    sub.company
  union select 'active_repos' as metric,
    sub.repo,
    sub.country,
    sub.author,
    sub.company,
    count(distinct sub.repo_id) as value
  from (
    select e.dup_repo_name as repo,
      a.country_name as country,
      a.login as author,
      coalesce(aa.company_name, '') as company,
      e.repo_id
    from
      gha_actors a,
      gha_events e
    left join
      gha_actors_affiliations aa
    on
      aa.actor_id = e.actor_id
      and aa.dt_from <= e.created_at
      and aa.dt_to > e.created_at
    where
      (e.actor_id = a.id or e.dup_actor_login = a.login)
      and {{period:e.created_at}}
      and (lower(a.login) {{exclude_bots}})
      and e.dup_repo_name in (select repo_name from trepos)
  ) sub
  where
    sub.country is not null
  group by
    sub.repo,
    sub.country,
    sub.author,
    sub.company
  union select 'comments' as metric,
    sub.repo,
    sub.country,
    sub.author,
    sub.company,
    count(distinct sub.id) as value
  from (
    select c.dup_repo_name as repo,
      a.country_name as country,
      a.login as author,
      coalesce(aa.company_name, '') as company,
      c.id
    from
      gha_actors a,
      gha_comments c
    left join
      gha_actors_affiliations aa
    on
      aa.actor_id = c.user_id
      and aa.dt_from <= c.created_at
      and aa.dt_to > c.created_at
    where
      (c.user_id = a.id or c.dup_user_login = a.login)
      and {{period:c.created_at}}
      and (lower(a.login) {{exclude_bots}})
      and c.dup_repo_name in (select repo_name from trepos)
  ) sub
  where
    sub.country is not null
  group by
    sub.repo,
    sub.country,
    sub.author,
    sub.company
  union select case sub.is_pull_request
      when true then 'prs'
      else 'issues'
    end as metric,
    sub.repo,
    sub.country,
    sub.author,
    sub.company,
    count(distinct sub.id) as value
  from (
    select i.dup_repo_name as repo,
      a.country_name as country,
      a.login as author,
      coalesce(aa.company_name, '') as company,
      i.id,
      i.is_pull_request
    from
      gha_actors a,
      gha_issues i
    left join
      gha_actors_affiliations aa
    on
      aa.actor_id = i.user_id
      and aa.dt_from <= i.created_at
      and aa.dt_to > i.created_at
    where
      (i.user_id = a.id or i.dup_user_login = a.login)
      and {{period:i.created_at}}
      and (lower(a.login) {{exclude_bots}})
      and i.dup_repo_name in (select repo_name from trepos)
  ) sub
  where
    sub.country is not null
  group by
    sub.is_pull_request,
    sub.repo,
    sub.country,
    sub.author,
    sub.company
  union select 'merged_prs' as metric,
    sub.repo,
    sub.country,
    sub.author,
    sub.company,
    count(distinct sub.id) as value
  from (
    select i.dup_repo_name as repo,
      a.country_name as country,
      a.login as author,
      coalesce(aa.company_name, '') as company,
      i.id
    from
      gha_actors a,
      gha_pull_requests i
    left join
      gha_actors_affiliations aa
    on
      aa.actor_id = i.user_id
      and aa.dt_from <= i.merged_at
      and aa.dt_to > i.merged_at
    where
      i.merged_at is not null
      and (i.user_id = a.id or i.dup_user_login = a.login)
      and {{period:i.merged_at}}
      and (lower(a.login) {{exclude_bots}})
      and i.dup_repo_name in (select repo_name from trepos)
  ) sub
  where
    sub.country is not null
  group by
    sub.repo,
    sub.country,
    sub.author,
    sub.company
  union select 'events' as metric,
    sub.repo,
    sub.country,
    sub.author,
    sub.company,
    count(distinct sub.id) as value
  from (
    select e.dup_repo_name as repo,
      a.country_name as country,
      a.login as author,
      coalesce(aa.company_name, '') as company,
      e.id
    from
      gha_actors a,
      gha_events e
    left join
      gha_actors_affiliations aa
    on
      aa.actor_id = e.actor_id
      and aa.dt_from <= e.created_at
      and aa.dt_to > e.created_at
    where
      (e.actor_id = a.id or e.dup_actor_login = a.login)
      and {{period:e.created_at}}
      and (lower(e.dup_actor_login) {{exclude_bots}})
      and e.dup_repo_name in (select repo_name from trepos)
  ) sub
  where
    sub.country is not null
  group by
    sub.repo,
    sub.country,
    sub.author,
    sub.company
  ) sub
/*where
  (sub.metric = 'events' and sub.value >= 20)
  or (sub.metric = 'active_repos' and sub.value >= 2)
  or (sub.metric = 'contributions' and sub.value >= 5)
  or (sub.metric = 'commit_comments' and sub.value >= 3)
  or (sub.metric = 'comments' and sub.value >= 5)
  or (sub.metric = 'issue_comments' and sub.value >= 5)
  or (sub.metric = 'review_comments' and sub.value >= 5)
  or (sub.metric in (
    'commits',
    'pushes',
    'issues',
    'prs',
    'merged_prs'
  )
)*/
order by
  metric asc,
  value desc,
  name asc
;
