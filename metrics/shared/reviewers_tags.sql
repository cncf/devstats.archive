with lgtm_texts as (
  select event_id
  from
    gha_texts
  where
    substring(body from '(?i)(?:^|\n|\r)\s*/(?:lgtm)\s*(?:\n|\r|$)') is not null
    and (actor_login {{exclude_bots}})
)
select
  distinct dup_actor_login
from
  gha_events
where
  (dup_actor_login {{exclude_bots}})
  and (
    type = 'PullRequestReviewCommentEvent'
    or id in (
      select min(event_id)
      from
        gha_issues_events_labels
      where
        label_name = 'lgtm'
      group by
        issue_id
      union select event_id from lgtm_texts
    )
  )
;
