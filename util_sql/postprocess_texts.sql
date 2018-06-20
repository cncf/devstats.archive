with var as (
  select
    coalesce(max(event_id), -9223372036854775808) as max_event_id
  from
    gha_texts
)
insert into gha_texts(
  event_id, body, created_at, repo_id, repo_name, actor_id, actor_login, type
) 
select
  event_id, body, created_at, dup_repo_id, dup_repo_name, dup_actor_id, dup_actor_login, dup_type
from
  gha_comments 
where
  body != ''
  and event_id > (select max_event_id from var)
union select
  event_id, message, dup_created_at, dup_repo_id, dup_repo_name, dup_actor_id, dup_actor_login, dup_type
from
  gha_commits
where
  message != ''
  and event_id > (select max_event_id from var)
union select
  event_id, title, created_at, dup_repo_id, dup_repo_name, dup_actor_id, dup_actor_login, dup_type
from
  gha_issues
where
  title != ''
  and event_id > (select max_event_id from var)
union select
  event_id, body, created_at, dup_repo_id, dup_repo_name, dup_actor_id, dup_actor_login, dup_type
from
  gha_issues
where
  body != ''
  and event_id > (select max_event_id from var)
union select 
  event_id, title, created_at, dup_repo_id, dup_repo_name, dup_actor_id, dup_actor_login, dup_type
from
  gha_pull_requests
where
  title != ''
  and event_id > (select max_event_id from var)
union select
  event_id, body, created_at, dup_repo_id, dup_repo_name, dup_actor_id, dup_actor_login, dup_type
from
  gha_pull_requests
where
  body != ''
  and event_id > (select max_event_id from var)
;
