select
  dup_actor_login as committer,
  count(distinct author_name) as cnt,
  string_agg(distinct author_name, ', ') as authors
from
  gha_commits
where
  dup_created_at >= '{{from}}'
  and dup_created_at < '{{to}}'
  and dup_type = 'PushEvent'
group by
  dup_actor_login
order by
  cnt desc
;
