create temp table prs as
select ipr.issue_id, pr.created_at, pr.merged_at as merged_at
from
  gha_issues_pull_requests ipr,
  gha_pull_requests pr
where
  pr.id = ipr.pull_request_id
  and pr.merged_at is not null
  and pr.created_at >= '{{from}}'
  and pr.created_at < '{{to}}'
  and pr.event_id = (
    select i.event_id from gha_pull_requests i where i.id = pr.id order by i.updated_at desc limit 1
  );

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

create temp table tdiffs as
select extract(epoch from lgtm.lgtm_at - prs.created_at) / 3600 as open_to_lgtm,
  extract(epoch from approve.approve_at - lgtm.lgtm_at) / 3600 as lgtm_to_approve,
  extract(epoch from prs.merged_at - approve.approve_at) / 3600 as approve_to_merge
  --prs.merged_at - approve.approve_at as approve_to_merge
from
  prs
join
  pr_lgtm lgtm on prs.issue_id = lgtm.issue_id
join
  pr_approve approve on prs.issue_id = approve.issue_id;

select
  'median_open_to_lgtm,median_lgtm_to_approve,median_approve_to_merge,percentile_75_open_to_lgtm,percentile_75_lgtm_to_approve,percentile_75_approve_to_merge' as name,
  percentile_disc(0.5) within group (order by open_to_lgtm asc) as m_o2l,
  percentile_disc(0.5) within group (order by lgtm_to_approve asc) as m_l2a,
  percentile_disc(0.5) within group (order by approve_to_merge asc) as m_a2m,
  percentile_disc(0.85) within group (order by open_to_lgtm asc) as pc_o2l,
  percentile_disc(0.85) within group (order by lgtm_to_approve asc) as pc_l2a,
  percentile_disc(0.85) within group (order by approve_to_merge asc) as pc_a2m
from
  tdiffs;

drop table tdiffs;
drop table pr_lgtm;
drop table pr_approve;
drop table prs;
