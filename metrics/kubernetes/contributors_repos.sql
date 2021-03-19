select 
  'cs;' || sub.metric || '_All_All_All;evs,acts' as metric,
  round(count(distinct sub.id) / {{n}}, 2) as evs,
  count(distinct sub.author) as acts
from (
  select case e.type
      when 'PushEvent' then 'pushes'
      when 'PullRequestReviewCommentEvent' then 'review_comments'
      when 'IssueCommentEvent' then 'issue_comments'
      when 'CommitCommentEvent' then 'commit_comments'
    end as metric,
    e.dup_actor_login as author,
    e.id
  from
    gha_events e
  where
    e.type in (
      'PushEvent', 'PullRequestReviewCommentEvent',
      'IssueCommentEvent', 'CommitCommentEvent'
    )
    and e.created_at >= '{{from}}'
    and e.created_at < '{{to}}'
    and (lower(e.dup_actor_login) {{exclude_bots}})
  union all select 'contributions' as metric,
    e.dup_actor_login as author,
    e.id
  from
    gha_events e
  where
    e.type in (
      'PushEvent', 'PullRequestEvent', 'IssuesEvent',
      'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
    )
    and e.created_at >= '{{from}}'
    and e.created_at < '{{to}}'
    and (lower(e.dup_actor_login) {{exclude_bots}})
  union all select 'comments' as metric,
    c.dup_user_login as author,
    c.id
  from
    gha_comments c
  where
    c.created_at >= '{{from}}'
    and c.created_at < '{{to}}'
    and (lower(c.dup_user_login) {{exclude_bots}})
  union all select 'issues' as metric,
    i.dup_user_login as author,
    i.id
  from
    gha_issues i
  where
    i.created_at >= '{{from}}'
    and i.created_at < '{{to}}'
    and i.is_pull_request = false
    and (lower(i.dup_user_login) {{exclude_bots}})
  union all select 'prs' as metric,
    i.dup_user_login as author,
    i.id
  from
    gha_issues i
  where
    i.created_at >= '{{from}}'
    and i.created_at < '{{to}}'
    and i.is_pull_request = true
    and (lower(i.dup_user_login) {{exclude_bots}})
  union all select 'merged_prs' as metric,
    i.dup_user_login as author,
    i.id
  from
    gha_pull_requests i
  where
    i.merged_at >= '{{from}}'
    and i.merged_at < '{{to}}'
    and (lower(i.dup_user_login) {{exclude_bots}})
  union all select 'events' as metric,
    e.dup_actor_login as author,
    e.id
  from
    gha_events e
  where
    e.created_at >= '{{from}}'
    and e.created_at < '{{to}}'
    and (lower(e.dup_actor_login) {{exclude_bots}})
  ) sub
group by
  sub.metric
union all select 'cs;' || sub.metric || '_' || sub.repo || '_All_All;evs,acts' as metric,
  round(count(distinct sub.id) / {{n}}, 2) as evs,
  count(distinct sub.author) as acts
from (
  select case sub.type
      when 'PushEvent' then 'pushes'
      when 'PullRequestReviewCommentEvent' then 'review_comments'
      when 'IssueCommentEvent' then 'issue_comments'
      when 'CommitCommentEvent' then 'commit_comments'
    end as metric,
    sub.repo,
    sub.author,
    sub.id
  from (
    select e.dup_repo_name as repo,
      e.type,
      e.dup_actor_login as author,
      e.id
    from
      gha_events e
    where
      e.type in (
        'PushEvent', 'PullRequestReviewCommentEvent',
        'IssueCommentEvent', 'CommitCommentEvent'
      )
      and e.created_at >= '{{from}}'
      and e.created_at < '{{to}}'
      and (lower(e.dup_actor_login) {{exclude_bots}})
      and e.dup_repo_name in (select repo_name from trepos)
  ) sub
  union all select 'contributions' as metric,
    sub.repo,
    sub.author,
    sub.id
  from (
    select e.dup_repo_name as repo,
      e.dup_actor_login as author,
      e.id
    from
      gha_events e
    where
      e.type in (
        'PushEvent', 'PullRequestEvent', 'IssuesEvent',
        'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
      )
      and e.created_at >= '{{from}}'
      and e.created_at < '{{to}}'
      and (lower(e.dup_actor_login) {{exclude_bots}})
      and e.dup_repo_name in (select repo_name from trepos)
  ) sub
  union all select 'comments' as metric,
    sub.repo,
    sub.author,
    sub.id
  from (
    select c.dup_repo_name as repo,
      c.dup_user_login as author,
      c.id
    from
      gha_comments c
    where
      c.created_at >= '{{from}}'
      and c.created_at < '{{to}}'
      and (lower(c.dup_user_login) {{exclude_bots}})
      and c.dup_repo_name in (select repo_name from trepos)
  ) sub
  union all select case sub.is_pull_request
      when true then 'prs'
      else 'issues'
    end as metric,
    sub.repo,
    sub.author,
    sub.id
  from (
    select i.dup_repo_name as repo,
      i.dup_user_login as author,
      i.id,
      i.is_pull_request
    from
      gha_issues i
    where
      i.created_at >= '{{from}}'
      and i.created_at < '{{to}}'
      and (lower(i.dup_user_login) {{exclude_bots}})
      and i.dup_repo_name in (select repo_name from trepos)
  ) sub
  union all select 'merged_prs' as metric,
    sub.repo,
    sub.author,
    sub.id
  from (
    select i.dup_repo_name as repo,
      i.dup_user_login as author,
      i.id
    from
      gha_pull_requests i
    where
      i.merged_at is not null
      and i.merged_at >= '{{from}}'
      and i.merged_at < '{{to}}'
      and (lower(i.dup_user_login) {{exclude_bots}})
      and i.dup_repo_name in (select repo_name from trepos)
  ) sub
  union all select 'events' as metric,
    sub.repo,
    sub.author,
    sub.id
  from (
    select e.dup_repo_name as repo,
      e.dup_actor_login as author,
      e.id
    from
      gha_events e
    where
      e.created_at >= '{{from}}'
      and e.created_at < '{{to}}'
      and (lower(e.dup_actor_login) {{exclude_bots}})
      and e.dup_repo_name in (select repo_name from trepos)
  ) sub
) sub
group by
  sub.metric,
  sub.repo
union all select 'cs;' || sub.metric || '_All_' || sub.country || '_All;evs,acts' as metric,
  round(count(distinct sub.id) / {{n}}, 2) as evs,
  count(distinct sub.author) as acts
from (
  select case e.type
      when 'PushEvent' then 'pushes'
      when 'PullRequestReviewCommentEvent' then 'review_comments'
      when 'IssueCommentEvent' then 'issue_comments'
      when 'CommitCommentEvent' then 'commit_comments'
    end as metric,
    a.country_name as country,
    a.login as author,
    e.id
  from
    gha_actors a,
    gha_events e
  where
    (e.actor_id = a.id or e.dup_actor_login = a.login)
    and e.type in (
      'PushEvent', 'PullRequestReviewCommentEvent',
      'IssueCommentEvent', 'CommitCommentEvent'
    )
    and e.created_at >= '{{from}}'
    and e.created_at < '{{to}}'
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
  union all select 'contributions' as metric,
    a.country_name as country,
    a.login as author,
    e.id
  from
    gha_actors a,
    gha_events e
  where
    (e.actor_id = a.id or e.dup_actor_login = a.login)
    and e.type in (
      'PushEvent', 'PullRequestEvent', 'IssuesEvent',
      'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
    )
    and e.created_at >= '{{from}}'
    and e.created_at < '{{to}}'
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
  union all select 'comments' as metric,
    a.country_name as country,
    a.login as author,
    c.id
  from
    gha_actors a,
    gha_comments c
  where
    (c.user_id = a.id or c.dup_user_login = a.login)
    and c.created_at >= '{{from}}'
    and c.created_at < '{{to}}'
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
  union all select 'issues' as metric,
    a.country_name as country,
    a.login as author,
    i.id
  from
    gha_actors a,
    gha_issues i
  where
    (i.user_id = a.id or i.dup_user_login = a.login)
    and i.created_at >= '{{from}}'
    and i.created_at < '{{to}}'
    and i.is_pull_request = false
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
  union all select 'prs' as metric,
    a.country_name as country,
    a.login as author,
    pr.id as value
  from
    gha_actors a,
    gha_issues pr
  where
    (pr.user_id = a.id or pr.dup_user_login = a.login)
    and pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
    and pr.is_pull_request = true
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
  union all select 'merged_prs' as metric,
    a.country_name as country,
    a.login as author,
    pr.id
  from
    gha_actors a,
    gha_pull_requests pr
  where
    (pr.user_id = a.id or pr.dup_user_login = a.login)
    and pr.merged_at is not null
    and pr.merged_at >= '{{from}}'
    and pr.merged_at < '{{to}}'
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
  union all select 'events' as metric,
    a.country_name as country,
    a.login as author,
    e.id
  from
    gha_actors a,
    gha_events e
  where
    (e.actor_id = a.id or e.dup_actor_login = a.login)
    and e.created_at >= '{{from}}'
    and e.created_at < '{{to}}'
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
  ) sub
group by
  sub.metric,
  sub.country
union all select 'cs;' || sub.metric || '_'|| sub.repo || '_' || sub.country || '_All;evs,acts' as metric,
  round(count(distinct sub.id) / {{n}}, 2) as evs,
  count(distinct sub.author) as acts
from (
  select case sub.type
      when 'PushEvent' then 'pushes'
      when 'PullRequestReviewCommentEvent' then 'review_comments'
      when 'IssueCommentEvent' then 'issue_comments'
      when 'CommitCommentEvent' then 'commit_comments'
    end as metric,
    sub.repo,
    sub.country,
    sub.author,
    sub.id
  from (
    select e.dup_repo_name as repo,
      e.type,
      a.country_name as country,
      a.login as author,
      e.id
    from
      gha_actors a,
      gha_events e
    where
      (e.actor_id = a.id or e.dup_actor_login = a.login)
      and e.type in (
        'PushEvent', 'PullRequestReviewCommentEvent',
        'IssueCommentEvent', 'CommitCommentEvent'
      )
      and e.created_at >= '{{from}}'
      and e.created_at < '{{to}}'
      and (lower(a.login) {{exclude_bots}})
      and e.dup_repo_name in (select repo_name from trepos)
  ) sub
  where
    sub.country is not null
  union all select 'contributions' as metric,
    sub.repo,
    sub.country,
    sub.author,
    sub.id
  from (
    select e.dup_repo_name as repo,
      a.country_name as country,
      a.login as author,
      e.id
    from
      gha_actors a,
      gha_events e
    where
      (e.actor_id = a.id or e.dup_actor_login = a.login)
      and e.type in (
        'PushEvent', 'PullRequestEvent', 'IssuesEvent',
        'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
      )
      and e.created_at >= '{{from}}'
      and e.created_at < '{{to}}'
      and (lower(a.login) {{exclude_bots}})
      and e.dup_repo_name in (select repo_name from trepos)
  ) sub
  where
    sub.country is not null
  union all select 'comments' as metric,
    sub.repo,
    sub.country,
    sub.author,
    sub.id
  from (
    select c.dup_repo_name as repo,
      a.country_name as country,
      a.login as author,
      c.id
    from
      gha_actors a,
      gha_comments c
    where
      (c.user_id = a.id or c.dup_user_login = a.login)
      and c.created_at >= '{{from}}'
      and c.created_at < '{{to}}'
      and (lower(a.login) {{exclude_bots}})
      and c.dup_repo_name in (select repo_name from trepos)
  ) sub
  where
    sub.country is not null
  union all select case sub.is_pull_request
      when true then 'prs'
      else 'issues'
    end as metric,
    sub.repo,
    sub.country,
    sub.author,
    sub.id
  from (
    select i.dup_repo_name as repo,
      a.country_name as country,
      a.login as author,
      i.id,
      i.is_pull_request
    from
      gha_actors a,
      gha_issues i
    where
      (i.user_id = a.id or i.dup_user_login = a.login)
      and i.created_at >= '{{from}}'
      and i.created_at < '{{to}}'
      and (lower(a.login) {{exclude_bots}})
      and i.dup_repo_name in (select repo_name from trepos)
  ) sub
  where
    sub.country is not null
  union all select 'merged_prs' as metric,
    sub.repo,
    sub.country,
    sub.author,
    sub.id
  from (
    select i.dup_repo_name as repo,
      a.country_name as country,
      a.login as author,
      i.id
    from
      gha_actors a,
      gha_pull_requests i
    where
      i.merged_at is not null
      and (i.user_id = a.id or i.dup_user_login = a.login)
      and i.merged_at >= '{{from}}'
      and i.merged_at < '{{to}}'
      and (lower(a.login) {{exclude_bots}})
      and i.dup_repo_name in (select repo_name from trepos)
  ) sub
  where
    sub.country is not null
  union all select 'events' as metric,
    sub.repo,
    sub.country,
    sub.author,
    sub.id
  from (
    select e.dup_repo_name as repo,
      a.country_name as country,
      a.login as author,
      e.id
    from
      gha_actors a,
      gha_events e
    where
      (e.actor_id = a.id or e.dup_actor_login = a.login)
      and e.created_at >= '{{from}}'
      and e.created_at < '{{to}}'
      and (lower(e.dup_actor_login) {{exclude_bots}})
      and e.dup_repo_name in (select repo_name from trepos)
  ) sub
  where
    sub.country is not null
  ) sub
group by
  sub.metric,
  sub.repo,
  sub.country
union all select 'cs;' || sub.metric || '_All_All_' || sub.company || ';evs,acts' as metric,
  round(count(distinct sub.id) / {{n}}, 2) as evs,
  count(distinct sub.author) as acts
from (
  select case e.type
      when 'PushEvent' then 'pushes'
      when 'PullRequestReviewCommentEvent' then 'review_comments'
      when 'IssueCommentEvent' then 'issue_comments'
      when 'CommitCommentEvent' then 'commit_comments'
    end as metric,
    e.dup_actor_login as author,
    aa.company_name as company,
    e.id
  from
    gha_events e,
    gha_actors_affiliations aa
  where
    aa.actor_id = e.actor_id
    and aa.dt_from <= e.created_at
    and aa.dt_to > e.created_at
    and e.type in (
      'PushEvent', 'PullRequestReviewCommentEvent',
      'IssueCommentEvent', 'CommitCommentEvent'
    )
    and e.created_at >= '{{from}}'
    and e.created_at < '{{to}}'
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and aa.company_name in (select companies_name from tcompanies)
  union all select 'contributions' as metric,
    e.dup_actor_login as author,
    aa.company_name as company,
    e.id
  from
    gha_events e,
    gha_actors_affiliations aa
  where
    aa.actor_id = e.actor_id
    and aa.dt_from <= e.created_at
    and aa.dt_to > e.created_at
    and e.type in (
      'PushEvent', 'PullRequestEvent', 'IssuesEvent',
      'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
    )
    and e.created_at >= '{{from}}'
    and e.created_at < '{{to}}'
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and aa.company_name in (select companies_name from tcompanies)
  union all select 'comments' as metric,
    c.dup_user_login as author,
    aa.company_name as company,
    c.id
  from
    gha_comments c,
    gha_actors_affiliations aa
  where
    aa.actor_id = c.user_id
    and aa.dt_from <= c.created_at
    and aa.dt_to > c.created_at
    and c.created_at >= '{{from}}'
    and c.created_at < '{{to}}'
    and (lower(c.dup_user_login) {{exclude_bots}})
    and aa.company_name in (select companies_name from tcompanies)
  union all select 'issues' as metric,
    i.dup_user_login as author,
    aa.company_name as company,
    i.id
  from
    gha_issues i,
    gha_actors_affiliations aa
  where
    aa.actor_id = i.user_id
    and aa.dt_from <= i.created_at
    and aa.dt_to > i.created_at
    and i.created_at >= '{{from}}'
    and i.created_at < '{{to}}'
    and i.is_pull_request = false
    and (lower(i.dup_user_login) {{exclude_bots}})
    and aa.company_name in (select companies_name from tcompanies)
  union all select 'prs' as metric,
    i.dup_user_login as author,
    aa.company_name as company,
    i.id
  from
    gha_issues i,
    gha_actors_affiliations aa
  where
    aa.actor_id = i.user_id
    and aa.dt_from <= i.created_at
    and aa.dt_to > i.created_at
    and i.created_at >= '{{from}}'
    and i.created_at < '{{to}}'
    and i.is_pull_request = true
    and (lower(i.dup_user_login) {{exclude_bots}})
    and aa.company_name in (select companies_name from tcompanies)
  union all select 'merged_prs' as metric,
    i.dup_user_login as author,
    aa.company_name as company,
    i.id
  from
    gha_pull_requests i,
    gha_actors_affiliations aa
  where
    aa.actor_id = i.user_id
    and i.merged_at is not null
    and aa.dt_from <= i.merged_at
    and aa.dt_to > i.merged_at
    and i.merged_at >= '{{from}}'
    and i.merged_at < '{{to}}'
    and (lower(i.dup_user_login) {{exclude_bots}})
    and aa.company_name in (select companies_name from tcompanies)
  union all select 'events' as metric,
    e.dup_actor_login as author,
    aa.company_name as company,
    e.id
  from
    gha_events e,
    gha_actors_affiliations aa
  where
    aa.actor_id = e.actor_id
    and aa.dt_from <= e.created_at
    and aa.dt_to > e.created_at
    and e.created_at >= '{{from}}'
    and e.created_at < '{{to}}'
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and aa.company_name in (select companies_name from tcompanies)
  ) sub
group by
  sub.metric,
  sub.company
union all select 'cs;' || sub.metric || '_' || sub.repo || '_All_' || sub.company || ';evs,acts' as metric,
  round(count(distinct sub.id) / {{n}}, 2) as evs,
  count(distinct sub.author) as acts
from (
  select case sub.type
      when 'PushEvent' then 'pushes'
      when 'PullRequestReviewCommentEvent' then 'review_comments'
      when 'IssueCommentEvent' then 'issue_comments'
      when 'CommitCommentEvent' then 'commit_comments'
    end as metric,
    sub.repo,
    sub.author,
    sub.company,
    sub.id
  from (
    select e.dup_repo_name as repo,
      e.type,
      e.dup_actor_login as author,
      aa.company_name as company,
      e.id
    from
      gha_actors_affiliations aa,
      gha_events e
    where
      aa.actor_id = e.actor_id
      and aa.dt_from <= e.created_at
      and aa.dt_to > e.created_at
      and e.type in (
        'PushEvent', 'PullRequestReviewCommentEvent',
        'IssueCommentEvent', 'CommitCommentEvent'
      )
      and e.created_at >= '{{from}}'
      and e.created_at < '{{to}}'
      and (lower(e.dup_actor_login) {{exclude_bots}})
      and aa.company_name in (select companies_name from tcompanies)
      and e.dup_repo_name in (select repo_name from trepos)
  ) sub
  union all select 'contributions' as metric,
    sub.repo,
    sub.author,
    sub.company,
    sub.id
  from (
    select e.dup_repo_name as repo,
      e.dup_actor_login as author,
      aa.company_name as company,
      e.id
    from
      gha_actors_affiliations aa,
      gha_events e
    where
      aa.actor_id = e.actor_id
      and aa.dt_from <= e.created_at
      and aa.dt_to > e.created_at
      and e.type in (
        'PushEvent', 'PullRequestEvent', 'IssuesEvent',
        'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
      )
      and e.created_at >= '{{from}}'
      and e.created_at < '{{to}}'
      and (lower(e.dup_actor_login) {{exclude_bots}})
      and aa.company_name in (select companies_name from tcompanies)
      and e.dup_repo_name in (select repo_name from trepos)
  ) sub
  union all select 'comments' as metric,
    sub.repo,
    sub.author,
    sub.company,
    sub.id
  from (
    select c.dup_repo_name as repo,
      c.dup_user_login as author,
      aa.company_name as company,
      c.id
    from
      gha_actors_affiliations aa,
      gha_comments c
    where
      aa.actor_id = c.user_id
      and aa.dt_from <= c.created_at
      and aa.dt_to > c.created_at
      and c.created_at >= '{{from}}'
      and c.created_at < '{{to}}'
      and (lower(c.dup_user_login) {{exclude_bots}})
      and aa.company_name in (select companies_name from tcompanies)
      and c.dup_repo_name in (select repo_name from trepos)
  ) sub
  union all select case sub.is_pull_request
      when true then 'prs'
      else 'issues'
    end as metric,
    sub.repo,
    sub.author,
    sub.company,
    sub.id
  from (
    select i.dup_repo_name as repo,
      i.dup_user_login as author,
      aa.company_name as company,
      i.id,
      i.is_pull_request
    from
      gha_actors_affiliations aa,
      gha_issues i
    where
      aa.actor_id = i.user_id
      and aa.dt_from <= i.created_at
      and aa.dt_to > i.created_at
      and i.created_at >= '{{from}}'
      and i.created_at < '{{to}}'
      and (lower(i.dup_user_login) {{exclude_bots}})
      and aa.company_name in (select companies_name from tcompanies)
      and i.dup_repo_name in (select repo_name from trepos)
  ) sub
  union all select 'merged_prs' as metric,
    sub.repo,
    sub.author,
    sub.company,
    sub.id
  from (
    select i.dup_repo_name as repo,
      i.dup_user_login as author,
      aa.company_name as company,
      i.id
    from
      gha_actors_affiliations aa,
      gha_pull_requests i
    where
      aa.actor_id = i.user_id
      and aa.dt_from <= i.merged_at
      and aa.dt_to > i.merged_at
      and i.merged_at is not null
      and i.merged_at >= '{{from}}'
      and i.merged_at < '{{to}}'
      and (lower(i.dup_user_login) {{exclude_bots}})
      and aa.company_name in (select companies_name from tcompanies)
      and i.dup_repo_name in (select repo_name from trepos)
  ) sub
  union all select 'events' as metric,
    sub.repo,
    sub.author,
    sub.company,
    sub.id
  from (
    select e.dup_repo_name as repo,
      e.dup_actor_login as author,
      aa.company_name as company,
      e.id
    from
      gha_actors_affiliations aa,
      gha_events e
    where
      aa.actor_id = e.actor_id
      and aa.dt_from <= e.created_at
      and aa.dt_to > e.created_at
      and e.created_at >= '{{from}}'
      and e.created_at < '{{to}}'
      and (lower(e.dup_actor_login) {{exclude_bots}})
      and aa.company_name in (select companies_name from tcompanies)
      and e.dup_repo_name in (select repo_name from trepos)
  ) sub
) sub
group by
  sub.metric,
  sub.repo,
  sub.company
union all select 'cs;' || sub.metric || '_All_' || sub.country || '_' || sub.company || ';evs,acts' as metric,
  round(count(distinct sub.id) / {{n}}, 2) as evs,
  count(distinct sub.author) as acts
from (
  select case e.type
      when 'PushEvent' then 'pushes'
      when 'PullRequestReviewCommentEvent' then 'review_comments'
      when 'IssueCommentEvent' then 'issue_comments'
      when 'CommitCommentEvent' then 'commit_comments'
    end as metric,
    a.country_name as country,
    a.login as author,
    aa.company_name as company,
    e.id
  from
    gha_actors a,
    gha_events e,
    gha_actors_affiliations aa
  where
    aa.actor_id = e.actor_id
    and aa.dt_from <= e.created_at
    and aa.dt_to > e.created_at
    and (e.actor_id = a.id or e.dup_actor_login = a.login)
    and e.type in (
      'PushEvent', 'PullRequestReviewCommentEvent',
      'IssueCommentEvent', 'CommitCommentEvent'
    )
    and e.created_at >= '{{from}}'
    and e.created_at < '{{to}}'
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
    and aa.company_name in (select companies_name from tcompanies)
  union all select 'contributions' as metric,
    a.country_name as country,
    a.login as author,
    aa.company_name as company,
    e.id
  from
    gha_actors a,
    gha_events e,
    gha_actors_affiliations aa
  where
    aa.actor_id = e.actor_id
    and aa.dt_from <= e.created_at
    and aa.dt_to > e.created_at
    and (e.actor_id = a.id or e.dup_actor_login = a.login)
    and e.type in (
      'PushEvent', 'PullRequestEvent', 'IssuesEvent',
      'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
    )
    and e.created_at >= '{{from}}'
    and e.created_at < '{{to}}'
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
    and aa.company_name in (select companies_name from tcompanies)
  union all select 'comments' as metric,
    a.country_name as country,
    a.login as author,
    aa.company_name as company,
    c.id
  from
    gha_actors a,
    gha_comments c,
    gha_actors_affiliations aa
  where
    aa.actor_id = c.user_id
    and aa.dt_from <= c.created_at
    and aa.dt_to > c.created_at
    and (c.user_id = a.id or c.dup_user_login = a.login)
    and c.created_at >= '{{from}}'
    and c.created_at < '{{to}}'
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
    and aa.company_name in (select companies_name from tcompanies)
  union all select 'issues' as metric,
    a.country_name as country,
    a.login as author,
    aa.company_name as company,
    i.id
  from
    gha_actors a,
    gha_issues i,
    gha_actors_affiliations aa
  where
    aa.actor_id = i.user_id
    and aa.dt_from <= i.created_at
    and aa.dt_to > i.created_at
    and (i.user_id = a.id or i.dup_user_login = a.login)
    and i.created_at >= '{{from}}'
    and i.created_at < '{{to}}'
    and i.is_pull_request = false
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
    and aa.company_name in (select companies_name from tcompanies)
  union all select 'prs' as metric,
    a.country_name as country,
    a.login as author,
    aa.company_name as company,
    pr.id
  from
    gha_actors a,
    gha_issues pr,
    gha_actors_affiliations aa
  where
    aa.actor_id = pr.user_id
    and aa.dt_from <= pr.created_at
    and aa.dt_to > pr.created_at
    and (pr.user_id = a.id or pr.dup_user_login = a.login)
    and pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
    and pr.is_pull_request = true
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
    and aa.company_name in (select companies_name from tcompanies)
  union all select 'merged_prs' as metric,
    a.country_name as country,
    a.login as author,
    aa.company_name as company,
    pr.id
  from
    gha_actors a,
    gha_pull_requests pr,
    gha_actors_affiliations aa
  where
    aa.actor_id = pr.user_id
    and aa.dt_from <= pr.merged_at
    and aa.dt_to > pr.merged_at
    and (pr.user_id = a.id or pr.dup_user_login = a.login)
    and pr.merged_at is not null
    and pr.merged_at >= '{{from}}'
    and pr.merged_at < '{{to}}'
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
    and aa.company_name in (select companies_name from tcompanies)
  union all select 'events' as metric,
    a.country_name as country,
    a.login as author,
    aa.company_name as company,
    e.id
  from
    gha_actors a,
    gha_events e,
    gha_actors_affiliations aa
  where
    aa.actor_id = e.actor_id
    and aa.dt_from <= e.created_at
    and aa.dt_to > e.created_at
    and (e.actor_id = a.id or e.dup_actor_login = a.login)
    and e.created_at >= '{{from}}'
    and e.created_at < '{{to}}'
    and (lower(a.login) {{exclude_bots}})
    and a.country_name is not null
    and aa.company_name in (select companies_name from tcompanies)
  ) sub
group by
  sub.metric,
  sub.country,
  sub.company
union all select 'cs;' || sub.metric || '_' || sub.repo || '_' || sub.country || '_' || sub.company || ';evs,acts' as metric,
  round(count(distinct sub.id) / {{n}}, 2) as evs,
  count(distinct sub.author) as acts
from (
  select case sub.type
      when 'PushEvent' then 'pushes'
      when 'PullRequestReviewCommentEvent' then 'review_comments'
      when 'IssueCommentEvent' then 'issue_comments'
      when 'CommitCommentEvent' then 'commit_comments'
    end as metric,
    sub.repo,
    sub.country,
    sub.author,
    sub.company,
    sub.id
  from (
    select e.dup_repo_name as repo,
      e.type,
      a.country_name as country,
      a.login as author,
      aa.company_name as company,
      e.id
    from
      gha_actors a,
      gha_actors_affiliations aa,
      gha_events e
    where
      aa.actor_id = e.actor_id
      and aa.dt_from <= e.created_at
      and aa.dt_to > e.created_at
      and (e.actor_id = a.id or e.dup_actor_login = a.login)
      and e.type in (
        'PushEvent', 'PullRequestReviewCommentEvent',
        'IssueCommentEvent', 'CommitCommentEvent'
      )
      and e.created_at >= '{{from}}'
      and e.created_at < '{{to}}'
      and (lower(a.login) {{exclude_bots}})
      and aa.company_name in (select companies_name from tcompanies)
      and e.dup_repo_name in (select repo_name from trepos)
  ) sub
  where
    sub.country is not null
  union all select 'contributions' as metric,
    sub.repo,
    sub.country,
    sub.author,
    sub.company,
    sub.id
  from (
    select e.dup_repo_name as repo,
      a.country_name as country,
      a.login as author,
      aa.company_name as company,
      e.id
    from
      gha_actors a,
      gha_actors_affiliations aa,
      gha_events e
    where
      aa.actor_id = e.actor_id
      and aa.dt_from <= e.created_at
      and aa.dt_to > e.created_at
      and (e.actor_id = a.id or e.dup_actor_login = a.login)
      and e.type in (
        'PushEvent', 'PullRequestEvent', 'IssuesEvent',
        'CommitCommentEvent', 'IssueCommentEvent', 'PullRequestReviewCommentEvent'
      )
      and e.created_at >= '{{from}}'
      and e.created_at < '{{to}}'
      and (lower(a.login) {{exclude_bots}})
      and aa.company_name in (select companies_name from tcompanies)
      and e.dup_repo_name in (select repo_name from trepos)
  ) sub
  where
    sub.country is not null
  union all select 'comments' as metric,
    sub.repo,
    sub.country,
    sub.author,
    sub.company,
    sub.id
  from (
    select c.dup_repo_name as repo,
      a.country_name as country,
      a.login as author,
      aa.company_name as company,
      c.id
    from
      gha_actors a,
      gha_actors_affiliations aa,
      gha_comments c
    where
      aa.actor_id = c.user_id
      and aa.dt_from <= c.created_at
      and aa.dt_to > c.created_at
      and (c.user_id = a.id or c.dup_user_login = a.login)
      and c.created_at >= '{{from}}'
      and c.created_at < '{{to}}'
      and (lower(a.login) {{exclude_bots}})
      and aa.company_name in (select companies_name from tcompanies)
      and c.dup_repo_name in (select repo_name from trepos)
  ) sub
  where
    sub.country is not null
  union all select case sub.is_pull_request
      when true then 'prs'
      else 'issues'
    end as metric,
    sub.repo,
    sub.country,
    sub.author,
    sub.company,
    sub.id
  from (
    select i.dup_repo_name as repo,
      a.country_name as country,
      a.login as author,
      aa.company_name as company,
      i.id,
      i.is_pull_request
    from
      gha_actors a,
      gha_actors_affiliations aa,
      gha_issues i
    where
      aa.actor_id = i.user_id
      and aa.dt_from <= i.created_at
      and aa.dt_to > i.created_at
      and (i.user_id = a.id or i.dup_user_login = a.login)
      and i.created_at >= '{{from}}'
      and i.created_at < '{{to}}'
      and (lower(a.login) {{exclude_bots}})
      and aa.company_name in (select companies_name from tcompanies)
      and i.dup_repo_name in (select repo_name from trepos)
  ) sub
  where
    sub.country is not null
  union all select 'merged_prs' as metric,
    sub.repo,
    sub.country,
    sub.author,
    sub.company,
    sub.id
  from (
    select i.dup_repo_name as repo,
      a.country_name as country,
      a.login as author,
      aa.company_name as company,
      i.id
    from
      gha_actors a,
      gha_actors_affiliations aa,
      gha_pull_requests i
    where
      aa.actor_id = i.user_id
      and aa.dt_from <= i.merged_at
      and aa.dt_to > i.merged_at
      and i.merged_at is not null
      and (i.user_id = a.id or i.dup_user_login = a.login)
      and i.merged_at >= '{{from}}'
      and i.merged_at < '{{to}}'
      and (lower(a.login) {{exclude_bots}})
      and aa.company_name in (select companies_name from tcompanies)
      and i.dup_repo_name in (select repo_name from trepos)
  ) sub
  where
    sub.country is not null
  union all select 'events' as metric,
    sub.repo,
    sub.country,
    sub.author,
    sub.company,
    sub.id
  from (
    select e.dup_repo_name as repo,
      a.country_name as country,
      a.login as author,
      aa.company_name as company,
      e.id
    from
      gha_actors a,
      gha_actors_affiliations aa,
      gha_events e
    where
      aa.actor_id = e.actor_id
      and aa.dt_from <= e.created_at
      and aa.dt_to > e.created_at
      and (e.actor_id = a.id or e.dup_actor_login = a.login)
      and e.created_at >= '{{from}}'
      and e.created_at < '{{to}}'
      and (lower(e.dup_actor_login) {{exclude_bots}})
      and aa.company_name in (select companies_name from tcompanies)
      and e.dup_repo_name in (select repo_name from trepos)
  ) sub
  where
    sub.country is not null
  ) sub
group by
  sub.metric,
  sub.repo,
  sub.country,
  sub.company
/*
order by
  acts desc,
  evs desc
*/
;
