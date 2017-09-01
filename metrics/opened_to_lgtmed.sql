create temp table pr_starts as
select issue_id, pull_request_created_at as created_at
from gha_issues_pull_requests
where pull_request_created_at >= '{{from}}' and pull_request_created_at < '{{to}}';

create temp table pr_ends as
select issue_id, min(created_at) as approved_at
from
  gha_issues_events_labels
where
  label_name = 'lgtm'
  and issue_id in (select issue_id from pr_starts)
group by
  issue_id;

select
  avg(extract(epoch from e.approved_at - s.created_at)/3600) as time_in_hours
from
  pr_starts s,
  pr_ends e
where
  s.issue_id = e.issue_id;


drop table pr_ends;
drop table pr_starts;
