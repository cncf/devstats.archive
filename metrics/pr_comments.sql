select
  count(distinct pl.comment_id) as cnt
from
  gha_payloads pl,
  gha_pull_requests pr
where
  pl.pull_request_id = pr.id
  and pl.comment_id is not null
  and pr.created_at >= '{{from}}'
  and pr.created_at < '{{to}}'
group by
  pull_request_id
union select 0 as cnt
order by cnt desc
limit 1;
