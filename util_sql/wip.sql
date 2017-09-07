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

create temp table pr_lgtm as
select issue_id, min(created_at) as lgtm_at
from
  gha_issues_events_labels
where
  label_name = 'lgtm'
  and issue_id in (select issue_id from prs)
group by
  issue_id;

create temp table pr_approve as
select issue_id, min(created_at) as approve_at
from
  gha_issues_events_labels
where
  label_name = 'approved'
  and issue_id in (select issue_id from prs)
group by
  issue_id;

select
  'hours_open_to_lgtm,hours_lgtm_to_approve,hours_approve_to_merge' as name,
  avg(extract(epoch from least(lgtm.lgtm_at, prs.merged_at) - prs.created_at)/3600) as hours_open_to_lgtm,
  avg(extract(epoch from least(approve.approve_at, prs.merged_at) - least(lgtm.lgtm_at, prs.merged_at))/3600) as hours_lgtm_to_approve,
  avg(extract(epoch from prs.merged_at - least(approve.approve_at, prs.merged_at))/3600) as hours_approve_to_merge
from
  prs
-- left join
join
  pr_lgtm lgtm on prs.issue_id = lgtm.issue_id
-- left join
join
  pr_approve approve on prs.issue_id = approve.issue_id
where
  prs.merged_at is not null;

drop table pr_lgtm;
drop table pr_approve;
drop table prs;
