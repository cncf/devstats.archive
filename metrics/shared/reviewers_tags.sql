with lgtm_texts as (
  select distinct event_id
  from
    gha_texts
  where
    substring(body from '(?i)(?:^|\n|\r)\s*/(?:lgtm)\s*(?:\n|\r|$)') is not null
    and (lower(actor_login) {{exclude_bots}})
    and created_at > now() - '3 months'::interval
)
select
  sub.dup_actor_login
from (
  select distinct dup_actor_login,
    count(id) as events
  from
    gha_events
  where
    (lower(dup_actor_login) {{exclude_bots}})
    and created_at > now() - '3 months'::interval
    and (
      type = 'PullRequestReviewCommentEvent'
      or id in (
        select min(event_id)
        from
          gha_issues_events_labels
        where
          label_name = 'lgtm'
          and created_at > now() - '3 months'::interval
        group by
          issue_id
        union select event_id from lgtm_texts
      )
    )
  group by
    dup_actor_login
  union select 'none', 0
) sub
order by
  sub.events desc
limit {{lim}}
;
