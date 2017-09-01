create temp table pr_starts as
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

create temp table pr_ends as
select issue_id, min(created_at) as approved_at
from
  gha_issues_events_labels
where
  label_name = 'approved'
  and issue_id in (select issue_id from pr_starts)
group by
  issue_id;

select
  avg(extract(epoch from least(e.approved_at, s.merged_at) - s.created_at)/3600) as time_in_hours
from
  pr_starts s
left join
  pr_ends e on s.issue_id = e.issue_id
where
  e.issue_id is not null
  or s.merged_at is not null;
drop table pr_ends;
drop table pr_starts;
