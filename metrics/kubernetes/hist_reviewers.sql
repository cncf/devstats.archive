create temp table matching as
select event_id
from
  gha_texts
where
  {{period:created_at}}
  and substring(body from '(?i)(?:^|\n|\r)\s*/(?:lgtm|approve)\s*(?:\n|\r|$)') is not null;

create temp table reviews as
select id as event_id
from
  gha_events
where
  {{period:created_at}}
  and type in ('PullRequestReviewCommentEvent');

select
  sub.repo_group,
  sub.actor,
  count(distinct sub.id) as reviews
from (
  select 'reviewers_hist,' || coalesce(ecf.repo_group, r.repo_group) as repo_group,
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
    and (e.dup_actor_login {{exclude_bots}})
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
union select 'reviewers_hist,All' as repo_group,
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
  and (dup_actor_login {{exclude_bots}})
group by
  dup_actor_login
having
  count(distinct id) >= 1
order by
  reviews desc,
  repo_group asc,
  actor asc
;

drop table reviews;
drop table matching;
