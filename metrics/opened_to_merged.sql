create temp table prs as
select ipr.issue_id, pr.created_at, min(pr.merged_at) as merged_at
from
  gha_issues_pull_requests ipr,
  gha_pull_requests pr
where
  pr.id = ipr.pull_request_id
  and pr.created_at >= '{{from}}'
  and pr.created_at < '{{to}}'
group by
  ipr.issue_id, pr.created_at;

select
  avg(extract(epoch from merged_at - created_at)/3600) as time_in_hours
from
  prs
where
  merged_at is not null
  and created_at >= '{{from}}'
  and created_at < '{{to}}';
drop table prs;
