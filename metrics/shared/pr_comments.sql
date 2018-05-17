with pr_comments as (
  select pl.pull_request_id as pr,
    count(distinct pl.comment_id) as cnt
  from
    gha_payloads pl,
    gha_pull_requests pr
  where
    pl.pull_request_id = pr.id
    and pl.comment_id is not null
    and pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
    and (lower(pr.dup_actor_login) {{exclude_bots}})
  group by
    pl.pull_request_id
)
select
  'pr_comms_med,pr_comms_p85,pr_comms_p95' as name,
  percentile_disc(0.5) within group (order by cnt asc) as median,
  percentile_disc(0.85) within group (order by cnt asc) as perentile_85,
  percentile_disc(0.95) within group (order by cnt asc) as perentile_95
from
  pr_comments
;
