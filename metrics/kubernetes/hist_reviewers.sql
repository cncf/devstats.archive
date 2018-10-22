with matching as (
  select event_id
  from
    gha_texts
  where
    {{period:created_at}}
    and substring(body from '(?i)(?:^|\n|\r)\s*/(?:lgtm|approve)\s*(?:\n|\r|$)') is not null
), reviews as (
  select id as event_id
  from
    gha_events
  where
    {{period:created_at}}
    and type in ('PullRequestReviewCommentEvent')
)
select
  'hdev_reviews,' || sub.repo_group || '_All' as metric ,
  sub.actor,
  count(distinct sub.id) as reviews
from (
  select coalesce(ecf.repo_group, r.repo_group) as repo_group,
    e.dup_actor_login as actor,
    e.id
  from
    gha_repos r,
    gha_events e
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = e.id
  where
    e.repo_id = r.id
    and (lower(e.dup_actor_login) {{exclude_bots}})
    and e.id in (
      select min(event_id)
      from
        gha_issues_events_labels
      where
        {{period:created_at}}
        and label_name in ('lgtm', 'approved')
      group by
        issue_id
      union select event_id from matching
      union select event_id from reviews
    )
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group,
  sub.actor
having
  count(distinct sub.id) >= 1
union select 'hdev_reviews,All_All' as metric,
  dup_actor_login as actor,
  count(distinct id) as reviews
from
  gha_events
where
  id in (
    select min(event_id)
    from
      gha_issues_events_labels
    where
      {{period:created_at}}
      and label_name in ('lgtm', 'approved')
    group by
      issue_id
    union select event_id from matching
    union select event_id from reviews
  )
  and (lower(dup_actor_login) {{exclude_bots}})
group by
  dup_actor_login
having
  count(distinct id) >= 1
union select 'hdev_reviews,' || sub.repo_group || '_' || sub.country as metric,
  sub.actor,
  count(distinct sub.id) as reviews
from (
  select coalesce(ecf.repo_group, r.repo_group) as repo_group,
    a.country_name as country,
    a.login as actor,
    e.id
  from
    gha_actors a,
    gha_repos r,
    gha_events e
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = e.id
  where
    (e.actor_id = a.id or e.dup_actor_login = a.login)
    and e.repo_id = r.id
    and (lower(a.login) {{exclude_bots}})
    and e.id in (
      select min(event_id)
      from
        gha_issues_events_labels
      where
        {{period:created_at}}
        and label_name in ('lgtm', 'approved')
      group by
        issue_id
      union select event_id from matching
      union select event_id from reviews
    )
  ) sub
where
  sub.repo_group is not null
  and sub.country is not null
group by
  sub.country,
  sub.repo_group,
  sub.actor
having
  count(distinct sub.id) >= 1
union select 'hdev_reviews,All_' || a.country_name as metric,
  a.login as actor,
  count(distinct e.id) as reviews
from
  gha_actors a,
  gha_events e
where
  (e.actor_id = a.id or e.dup_actor_login = a.login)
  and e.id in (
    select min(event_id)
    from
      gha_issues_events_labels
    where
      {{period:created_at}}
      and label_name in ('lgtm', 'approved')
    group by
      issue_id
    union select event_id from matching
    union select event_id from reviews
  )
  and (lower(a.login) {{exclude_bots}})
  and a.country_name is not null
group by
  a.country_name,
  a.login
having
  count(distinct e.id) >= 1
order by
  reviews desc,
  metric asc,
  actor asc
;
