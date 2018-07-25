with var as (
  select
    coalesce(max(event_id), -9223372036854775808) as max_event_id,
    0 as opt
  from
    gha_issues_events_labels
  where
    type like '%Event'
  union select coalesce(max(event_id), 281474976710657) as max_event_id,
    1 as opt
  from
    gha_issues_events_labels
  where
    type not like '%Event'
    and type != 'sync'
  union select coalesce(max(event_id), 329900000000000) as max_event_id,
    2 as opt
  from
    gha_issues_events_labels
  where
    type = 'sync'
)
insert into gha_issues_events_labels(
  issue_id, event_id, label_id, label_name, created_at,
  repo_id, repo_name, actor_id, actor_login, type, issue_number
)
select
  il.issue_id, il.event_id, lb.id, lb.name, il.dup_created_at,
  il.dup_repo_id, il.dup_repo_name, il.dup_actor_id, il.dup_actor_login, il.dup_type, il.dup_issue_number
from
  gha_issues_labels il,
  gha_labels lb
where
  il.label_id = lb.id
  and (
    (
      il.event_id > (
        select max_event_id from var where opt = 0
      )
      and il.event_id < 281474976710657
    )
    or (
      il.event_id > (
        select max_event_id from var where opt = 1
      )
      and il.event_id >= 281474976710657
      and il.event_id < 329900000000000
    )
    or (
      il.event_id > (
        select max_event_id from var where opt = 2
      )
      and il.event_id >= 329900000000000
    )
  )
;
