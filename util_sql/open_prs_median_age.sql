with prs as (
  select pr.id,
    pr.dup_repo_id as repo_id,
    pr.dup_repo_name as repo_name,
    pr.created_at,
    pr.merged_at,
    pr.event_id
  from
    gha_pull_requests pr
  where
    pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
    and pr.event_id = (
      select s.event_id from gha_pull_requests s where s.id = pr.id order by s.updated_at desc limit 1
    )
    and pr.dup_repo_name = 'kubernetes/kubernetes'
), tdiffs as (
  select id,
--    extract(epoch from coalesce(merged_at - created_at, '{{to}}' - created_at)) / 3600 as age
    extract(epoch from coalesce(merged_at - created_at, now() - created_at)) / 3600 as age
  from
    prs
)
select
  count(distinct id) as num,
  percentile_disc(0.5) within group (order by age asc) as age_median
from
  tdiffs
;
