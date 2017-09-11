select
  count(*) as cnt
from
  gha_payloads
where
  pull_request_id is not null
  and comment_id is not null
  and dup_created_at >= '{{from}}'
  and dup_created_at < '{{to}}'
group by
  pull_request_id
order by cnt desc
limit 1;
