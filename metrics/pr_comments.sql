create temp table pr_comments as
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
group by
  pl.pull_request_id;

select
  'pr_comments_median,pr_comments_percentile_85,pr_comments_percentile_95' as name,
  percentile_disc(0.5) within group (order by cnt asc) as median,
  percentile_disc(0.85) within group (order by cnt asc) as perentile_85,
  percentile_disc(0.95) within group (order by cnt asc) as perentile_95
from
  pr_comments;

drop table pr_comments;
