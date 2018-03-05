create temp table lgtm_texts as
select event_id
from gha_texts
where
  created_at >= '{{from}}'
  and created_at < '{{to}}'
  and substring(body from '(?i)(?:^|\n|\r)\s*/(?:lgtm)\s*(?:\n|\r|$)') is not null
  and (actor_login {{exclude_bots}})
;

select
  concat('lgtms_per_user,', dup_actor_login, '`All') as repo_group_user,
  count(distinct id) as result
from
  gha_events
where
  (dup_actor_login {{exclude_bots}})
  and id in (
    select min(event_id)
    from
      gha_issues_events_labels
    where
      created_at >= '{{from}}'
      and created_at < '{{to}}'
      and label_name = 'lgtm'
    group by
      issue_id
    union select event_id from lgtm_texts
  )
group by
  dup_actor_login
union select concat('reviews_per_user,', dup_actor_login, '`All') as repo_group_user,
  count(distinct id) as result
from
  gha_events
where
  created_at >= '{{from}}'
  and created_at < '{{to}}'
  and type in ('PullRequestReviewCommentEvent')
  and (dup_actor_login {{exclude_bots}})
group by
  dup_actor_login
union select sub.repo_group_user,
  count(distinct sub.event_id) as result
from (
  select 'reviews_per_user,' || concat(e.dup_actor_login, '`', coalesce(ecf.repo_group, r.repo_group)) as repo_group_user,
    coalesce(ecf.repo_group, r.repo_group) as repo_group,
    e.id as event_id
  from
    gha_repos r,
    gha_events e
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = e.id
  where
    e.repo_id = r.id
    and (e.dup_actor_login {{exclude_bots}})
    and e.type in ('PullRequestReviewCommentEvent')
    and e.created_at >= '{{from}}'
    and e.created_at < '{{to}}'
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group_user
union select sub.repo_group_user,
  count(distinct sub.event_id) as result
from (
  select 'lgtms_per_user,' || concat(e.dup_actor_login, '`', coalesce(ecf.repo_group, r.repo_group)) as repo_group_user,
    coalesce(ecf.repo_group, r.repo_group) as repo_group,
    e.id as event_id
  from
    gha_repos r,
    gha_events e
  left join
    gha_events_commits_files ecf
  on
    ecf.event_id = e.id
  where
    e.repo_id = r.id
    and (e.dup_actor_login {{exclude_bots}})
    and e.id in (
      select min(event_id)
      from
        gha_issues_events_labels
      where
        created_at >= '{{from}}'
        and created_at < '{{to}}'
        and label_name = 'lgtm'
      group by
        issue_id
      union select event_id from lgtm_texts
    )
  ) sub
where
  sub.repo_group is not null
group by
  sub.repo_group_user
order by
  result desc,
  repo_group_user asc
;

drop table lgtm_texts;
