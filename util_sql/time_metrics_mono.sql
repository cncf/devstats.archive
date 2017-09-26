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
  and pr.dup_repo_id in (select id from gha_repos where repo_group in ('Kubernetes', 'Contrib'))
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

create temp table ranges as
select prs.created_at as open,
  lgtm.lgtm_at as lgtm,
  approve.approve_at as approve,
  prs.merged_at as merge
from
  prs
left join
  pr_lgtm lgtm on prs.issue_id = lgtm.issue_id
left join
  pr_approve approve on prs.issue_id = approve.issue_id;

create temp table tdiffs as
select extract(epoch from coalesce(lgtm - open, approve - open, merge - open)) / 3600 as open_to_lgtm,
  extract(epoch from coalesce(approve - lgtm, merge - lgtm, '0'::interval)) / 3600 as lgtm_to_approve,
  extract(epoch from coalesce(merge - approve, '0'::interval)) / 3600 as approve_to_merge
from
  ranges;

select
  'mono_median_open_to_lgtm,mono_median_lgtm_to_approve,mono_median_approve_to_merge,mono_percentile_85_open_to_lgtm,mono_percentile_85_lgtm_to_approve,mono_percentile_85_approve_to_merge' as name,
  percentile_disc(0.5) within group (order by open_to_lgtm asc) as m_o2l,
  percentile_disc(0.5) within group (order by lgtm_to_approve asc) as m_l2a,
  percentile_disc(0.5) within group (order by approve_to_merge asc) as m_a2m,
  percentile_disc(0.85) within group (order by open_to_lgtm asc) as pc_o2l,
  percentile_disc(0.85) within group (order by lgtm_to_approve asc) as pc_l2a,
  percentile_disc(0.85) within group (order by approve_to_merge asc) as pc_a2m
from
  tdiffs;

drop table tdiffs;
drop table ranges;
drop table pr_lgtm;
drop table pr_approve;
drop table prs;
