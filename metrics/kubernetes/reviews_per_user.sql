with lgtm_texts as (
  select event_id
  from gha_texts
  where
    created_at >= '{{from}}'
    and created_at < '{{to}}'
    and substring(body from '(?i)(?:^|\n|\r)\s*/(?:lgtm)\s*(?:\n|\r|$)') is not null
    and actor_login in (select reviewers_name from treviewers)
)
select
  concat('ulgtms,', dup_actor_login, '`All') as repo_user,
  round(count(id) / {{n}}, 2) as result
from
  gha_events
where
  dup_actor_login in (select reviewers_name from treviewers)
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
union select concat('reviews_per_user,', dup_actor_login, '`All') as repo_user,
  round(count(id) / {{n}}, 2) as result
from
  gha_events
where
  created_at >= '{{from}}'
  and created_at < '{{to}}'
  and type in ('PullRequestReviewCommentEvent')
  and dup_actor_login in (select reviewers_name from treviewers)
group by
  dup_actor_login
union select 'reviews_per_user,' || concat(dup_actor_login, '`', dup_repo_name) as repo_user,
  round(count(id) / {{n}}, 2) as result
from
  gha_events
where
  dup_actor_login in (select reviewers_name from treviewers)
  and type in ('PullRequestReviewCommentEvent')
  and created_at >= '{{from}}'
  and created_at < '{{to}}'
group by
  repo_user
union select 'ulgtms,' || concat(dup_actor_login, '`', dup_repo_name) as repo_user,
  round(count(id) / {{n}}, 2) as result
from
  gha_events
where
  dup_actor_login in (select reviewers_name from treviewers)
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
  repo_user
order by
  result desc,
  repo_user asc
;
