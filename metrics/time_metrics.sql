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

create temp table prs_groups as
select r.repo_group,
  ipr.issue_id,
  pr.created_at,
  pr.merged_at as merged_at
from
  gha_issues_pull_requests ipr,
  gha_pull_requests pr,
  gha_repos r
where
  r.id = ipr.repo_id
  and r.repo_group is not null
  and pr.id = ipr.pull_request_id
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

create temp table ranges_groups as
select prs_groups.repo_group as repo_group,
  prs_groups.created_at as open,
  lgtm.lgtm_at as lgtm,
  approve.approve_at as approve,
  prs_groups.merged_at as merge
from
  prs_groups
left join
  pr_lgtm lgtm on prs_groups.issue_id = lgtm.issue_id
left join
  pr_approve approve on prs_groups.issue_id = approve.issue_id;

create temp table tdiffs as
select extract(epoch from coalesce(lgtm - open, approve - open, merge - open)) / 3600 as open_to_lgtm,
  extract(epoch from coalesce(approve - lgtm, merge - lgtm, '0'::interval)) / 3600 as lgtm_to_approve,
  extract(epoch from coalesce(merge - approve, '0'::interval)) / 3600 as approve_to_merge
from
  ranges;

create temp table tdiffs_groups as
select repo_group,
  extract(epoch from coalesce(lgtm - open, approve - open, merge - open)) / 3600 as open_to_lgtm,
  extract(epoch from coalesce(approve - lgtm, merge - lgtm, '0'::interval)) / 3600 as lgtm_to_approve,
  extract(epoch from coalesce(merge - approve, '0'::interval)) / 3600 as approve_to_merge
from
  ranges_groups;

select
  'time_metrics;All;median_open_to_lgtm,median_lgtm_to_approve,median_approve_to_merge,percentile_85_open_to_lgtm,percentile_85_lgtm_to_approve,percentile_85_approve_to_merge' as name,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc), 0) as m_o2l,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc), 0) as m_l2a,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc), 0) as m_a2m,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc), 0) as pc_o2l,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc), 0) as pc_l2a,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc), 0) as pc_a2m
from
  tdiffs
union select 'time_metrics;' || repo_group || ';median_open_to_lgtm,median_lgtm_to_approve,median_approve_to_merge,percentile_85_open_to_lgtm,percentile_85_lgtm_to_approve,percentile_85_approve_to_merge' as name,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc), 0) as m_o2l,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc), 0) as m_l2a,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc), 0) as m_a2m,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc), 0) as pc_o2l,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc), 0) as pc_l2a,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc), 0) as pc_a2m
from
  tdiffs_groups
group by
  repo_group
order by
  name asc
;

drop table tdiffs;
drop table tdiffs_groups;
drop table ranges;
drop table ranges_groups;
drop table pr_lgtm;
drop table pr_approve;
drop table prs;
drop table prs_groups;
