select 
  'project_company_stats,' || sub.name,
  sub.value
from (
  select 'Commits' as name,
    af.company_name as company,
    count(distinct c.sha) as value
  from
    gha_commits c,
    gha_actors_affiliations af
  where
    c.dup_actor_id = af.actor_id
    and af.dt_from <= c.dup_created_at
    and af.dt_to > c.dup_created_at
    and c.dup_created_at >= now() - '{{period}}'::interval
    and c.dup_actor_login not in ('googlebot')
    and c.dup_actor_login not like 'k8s-%'
    and c.dup_actor_login not like '%-bot'
    and c.dup_actor_login not like '%-robot'
  group by
    af.company_name
  union select case e.type 
      when 'IssuesEvent' then 'Issue creators'
      when 'PullRequestEvent' then 'PR creators'
      when 'PushEvent' then 'Committers'
      when 'PullRequestReviewCommentEvent' then 'PR reviewers'
      when 'IssueCommentEvent' then 'Issue commenters'
      when 'CommitCommentEvent' then 'Commit commenters'
      when 'WatchEvent' then 'Watchers'
      when 'ForkEvent' then 'Forkers'
    end as name,
    af.company_name as company,
    count(distinct e.actor_id) as value
  from
    gha_events e,
    gha_actors_affiliations af
  where
    e.actor_id = af.actor_id
    and af.dt_from <= e.created_at
    and af.dt_to > e.created_at
    and e.type in (
      'IssuesEvent', 'PullRequestEvent', 'PushEvent',
      'PullRequestReviewCommentEvent', 'IssueCommentEvent',
      'CommitCommentEvent', 'ForkEvent', 'WatchEvent'
    )
    and e.created_at >= now() - '{{period}}'::interval
    and e.dup_actor_login not in ('googlebot')
    and e.dup_actor_login not like 'k8s-%'
    and e.dup_actor_login not like '%-bot'
    and e.dup_actor_login not like '%-robot'
  group by
    e.type,
    af.company_name
  union select 'Repositories' as name,
    af.company_name as company,
    count(distinct e.repo_id) as value
  from
    gha_events e,
    gha_actors_affiliations af
  where
    e.actor_id = af.actor_id
    and af.dt_from <= e.created_at
    and af.dt_to > e.created_at
    and e.created_at >= now() - '{{period}}'::interval
  group by
    af.company_name
  union select 'Comments' as name,
    af.company_name as company,
    count(distinct c.id) as value
  from
    gha_comments c,
    gha_actors_affiliations af
  where
    c.user_id = af.actor_id
    and af.dt_from <= c.created_at
    and af.dt_to > c.created_at
    and c.created_at >= now() - '{{period}}'::interval
    and c.dup_user_login not in ('googlebot')
    and c.dup_user_login not like 'k8s-%'
    and c.dup_user_login not like '%-bot'
    and c.dup_user_login not like '%-robot'
  group by
    af.company_name
  union select 'Commenters' as name,
    af.company_name as company,
    count(distinct c.user_id) as value
  from
    gha_comments c,
    gha_actors_affiliations af
  where
    c.user_id = af.actor_id
    and af.dt_from <= c.created_at
    and af.dt_to > c.created_at
    and c.created_at >= now() - '{{period}}'::interval
    and c.dup_user_login not in ('googlebot')
    and c.dup_user_login not like 'k8s-%'
    and c.dup_user_login not like '%-bot'
    and c.dup_user_login not like '%-robot'
  group by
    af.company_name
  union select 'Issues' as name,
    af.company_name as company,
    count(distinct i.id) as value
  from
    gha_issues i,
    gha_actors_affiliations af
  where
    i.user_id = af.actor_id
    and af.dt_from <= i.created_at
    and af.dt_to > i.created_at
    and i.created_at >= now() - '{{period}}'::interval
    and i.is_pull_request = false
    and i.dup_user_login not in ('googlebot')
    and i.dup_user_login not like 'k8s-%'
    and i.dup_user_login not like '%-bot'
    and i.dup_user_login not like '%-robot'
  group by
    af.company_name
  union select 'PRs' as name,
    af.company_name as company,
    count(distinct i.id) as value
  from
    gha_issues i,
    gha_actors_affiliations af
  where
    i.user_id = af.actor_id
    and af.dt_from <= i.created_at
    and af.dt_to > i.created_at
    and i.created_at >= now() - '{{period}}'::interval
    and i.is_pull_request = true
    and i.dup_user_login not in ('googlebot')
    and i.dup_user_login not like 'k8s-%'
    and i.dup_user_login not like '%-bot'
    and i.dup_user_login not like '%-robot'
  group by
    af.company_name
  union select 'Events' as name,
    af.company_name as company,
    count(e.id) as value
  from
    gha_events e,
    gha_actors_affiliations af
  where
    e.actor_id = af.actor_id
    and af.dt_from <= e.created_at
    and af.dt_to > e.created_at
    and e.created_at >= now() - '{{period}}'::interval
    and e.dup_actor_login not in ('googlebot')
    and e.dup_actor_login not like 'k8s-%'
    and e.dup_actor_login not like '%-bot'
    and e.dup_actor_login not like '%-robot'
  group by
    af.company_name
  ) sub
;
