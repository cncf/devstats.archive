with prs as (
  select distinct ipr.issue_id,
    pr.created_at,
    pr.merged_at as merged_at,
    case iel.label_name when 'kind/api-change' then 'yes' else 'no' end as api_change
  from
    gha_pull_requests pr
  join
    gha_issues_pull_requests ipr
  on
    pr.id = ipr.pull_request_id
    and pr.merged_at is not null
    and pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
    and pr.event_id = (
      select i.event_id from gha_pull_requests i where i.id = pr.id order by i.updated_at desc limit 1
    )
  left join
    gha_issues_events_labels iel
  on
    ipr.issue_id = iel.issue_id
    and iel.label_name = 'kind/api-change'
), prs_groups as (
  select sub.repo_group,
    sub.issue_id,
    sub.created_at,
    sub.merged_at,
    sub.api_change
  from (
    select distinct coalesce(ecf.repo_group, r.repo_group) as repo_group,
      ipr.issue_id,
      pr.created_at,
      pr.merged_at as merged_at,
      case iel.label_name when 'kind/api-change' then 'yes' else 'no' end as api_change
    from
      gha_repos r
    join
      gha_pull_requests pr
    on
      pr.merged_at is not null
      and pr.created_at >= '{{from}}'
      and pr.created_at < '{{to}}'
      and pr.event_id = (
        select i.event_id from gha_pull_requests i where i.id = pr.id order by i.updated_at desc limit 1
      )
    join
      gha_issues_pull_requests ipr
    on
      r.id = ipr.repo_id
      and pr.id = ipr.pull_request_id
    left join
      gha_events_commits_files ecf
    on
      ecf.event_id = pr.event_id
    left join
      gha_issues_events_labels iel
    on
      ipr.issue_id = iel.issue_id
      and iel.label_name = 'kind/api-change'
    ) sub
  where
    sub.repo_group is not null
), pr_lgtm as (
  select issue_id, min(created_at) as lgtm_at
  from
    gha_issues_events_labels
  where
    label_name = 'lgtm'
    and issue_id in (select issue_id from prs)
  group by
    issue_id
), pr_approve as (
  select issue_id, min(created_at) as approve_at
  from
    gha_issues_events_labels
  where
    label_name = 'approved'
    and issue_id in (select issue_id from prs)
  group by
    issue_id
), ranges as (
  select prs.issue_id,
    prs.created_at as open,
    lgtm.lgtm_at as lgtm,
    approve.approve_at as approve,
    prs.merged_at as merge,
    prs.api_change as api_change
  from
    prs
  left join
    pr_lgtm lgtm on prs.issue_id = lgtm.issue_id
  left join
    pr_approve approve on prs.issue_id = approve.issue_id
), ranges_groups as (
  select prs_groups.issue_id,
    prs_groups.repo_group as repo_group,
    prs_groups.created_at as open,
    lgtm.lgtm_at as lgtm,
    approve.approve_at as approve,
    prs_groups.merged_at as merge,
    prs_groups.api_change as api_change
  from
    prs_groups
  left join
    pr_lgtm lgtm on prs_groups.issue_id = lgtm.issue_id
  left join
    pr_approve approve on prs_groups.issue_id = approve.issue_id
), tdiffs as (
  select issue_id,
    api_change,
    extract(epoch from coalesce(lgtm - open, approve - open, merge - open)) / 3600 as open_to_lgtm,
    extract(epoch from coalesce(approve - lgtm, merge - lgtm, '0'::interval)) / 3600 as lgtm_to_approve,
    extract(epoch from coalesce(merge - approve, '0'::interval)) / 3600 as approve_to_merge
  from
    ranges
), tdiffs_groups as (
  select issue_id,
    repo_group,
    api_change,
    extract(epoch from coalesce(lgtm - open, approve - open, merge - open)) / 3600 as open_to_lgtm,
    extract(epoch from coalesce(approve - lgtm, merge - lgtm, '0'::interval)) / 3600 as lgtm_to_approve,
    extract(epoch from coalesce(merge - approve, '0'::interval)) / 3600 as approve_to_merge
  from
    ranges_groups
)
select
  'tmet;All_All_All;'
  || 'amedo2l,amedl2a,ameda2m,ap85o2l,ap85l2a,ap85a2m,'
  || 'ymedo2l,ymedl2a,ymeda2m,yp85o2l,yp85l2a,yp85a2m,'
  || 'nmedo2l,nmedl2a,nmeda2m,np85o2l,np85l2a,np85a2m'
  as name,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc), 0) as m_o2l_a,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc), 0) as m_l2a_a,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc), 0) as m_a2m_a,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc), 0) as pc_o2l_a,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc), 0) as pc_l2a_a,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc), 0) as pc_a2m_a,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc) filter (where api_change = 'yes'), 0) as m_o2l_y,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc) filter (where api_change = 'yes'), 0) as m_l2a_y,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc) filter (where api_change = 'yes'), 0) as m_a2m_y,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc) filter (where api_change = 'yes'), 0) as pc_o2l_y,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc) filter (where api_change = 'yes'), 0) as pc_l2a_y,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc) filter (where api_change = 'yes'), 0) as pc_a2m_y,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc) filter (where api_change = 'no'), 0) as m_o2l_n,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc) filter (where api_change = 'no'), 0) as m_l2a_n,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc) filter (where api_change = 'no'), 0) as m_a2m_n,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc) filter (where api_change = 'no'), 0) as pc_o2l_n,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc) filter (where api_change = 'no'), 0) as pc_l2a_n,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc) filter (where api_change = 'no'), 0) as pc_a2m_n
from
  tdiffs
union select 'tmet;' || repo_group || '_All_All;'
  || 'amedo2l,amedl2a,ameda2m,ap85o2l,ap85l2a,ap85a2m,'
  || 'ymedo2l,ymedl2a,ymeda2m,yp85o2l,yp85l2a,yp85a2m,'
  || 'nmedo2l,nmedl2a,nmeda2m,np85o2l,np85l2a,np85a2m'
  as name,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc), 0) as m_o2l_a,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc), 0) as m_l2a_a,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc), 0) as m_a2m_a,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc), 0) as pc_o2l_a,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc), 0) as pc_l2a_a,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc), 0) as pc_a2m_a,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc) filter (where api_change = 'yes'), 0) as m_o2l_y,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc) filter (where api_change = 'yes'), 0) as m_l2a_y,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc) filter (where api_change = 'yes'), 0) as m_a2m_y,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc) filter (where api_change = 'yes'), 0) as pc_o2l_y,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc) filter (where api_change = 'yes'), 0) as pc_l2a_y,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc) filter (where api_change = 'yes'), 0) as pc_a2m_y,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc) filter (where api_change = 'no'), 0) as m_o2l_n,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc) filter (where api_change = 'no'), 0) as m_l2a_n,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc) filter (where api_change = 'no'), 0) as m_a2m_n,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc) filter (where api_change = 'no'), 0) as pc_o2l_n,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc) filter (where api_change = 'no'), 0) as pc_l2a_n,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc) filter (where api_change = 'no'), 0) as pc_a2m_n
from
  tdiffs_groups
group by
  repo_group
union select 'tmet;All_' || substring(iel.label_name from 6) || '_All;'
  || 'amedo2l,amedl2a,ameda2m,ap85o2l,ap85l2a,ap85a2m,'
  || 'ymedo2l,ymedl2a,ymeda2m,yp85o2l,yp85l2a,yp85a2m,'
  || 'nmedo2l,nmedl2a,nmeda2m,np85o2l,np85l2a,np85a2m'
  as name,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc), 0) as m_o2l_a,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc), 0) as m_l2a_a,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc), 0) as m_a2m_a,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc), 0) as pc_o2l_a,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc), 0) as pc_l2a_a,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc), 0) as pc_a2m_a,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc) filter (where api_change = 'yes'), 0) as m_o2l_y,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc) filter (where api_change = 'yes'), 0) as m_l2a_y,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc) filter (where api_change = 'yes'), 0) as m_a2m_y,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc) filter (where api_change = 'yes'), 0) as pc_o2l_y,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc) filter (where api_change = 'yes'), 0) as pc_l2a_y,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc) filter (where api_change = 'yes'), 0) as pc_a2m_y,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc) filter (where api_change = 'no'), 0) as m_o2l_n,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc) filter (where api_change = 'no'), 0) as m_l2a_n,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc) filter (where api_change = 'no'), 0) as m_a2m_n,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc) filter (where api_change = 'no'), 0) as pc_o2l_n,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc) filter (where api_change = 'no'), 0) as pc_l2a_n,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc) filter (where api_change = 'no'), 0) as pc_a2m_n
from
  tdiffs t,
  gha_issues_events_labels iel
where
  t.issue_id = iel.issue_id
  and iel.label_name like 'size/%'
group by
  iel.label_name
union select 'tmet;' || repo_group || '_' || substring(iel.label_name from 6) || '_All;'
  || 'amedo2l,amedl2a,ameda2m,ap85o2l,ap85l2a,ap85a2m,'
  || 'ymedo2l,ymedl2a,ymeda2m,yp85o2l,yp85l2a,yp85a2m,'
  || 'nmedo2l,nmedl2a,nmeda2m,np85o2l,np85l2a,np85a2m'
  as name,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc), 0) as m_o2l_a,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc), 0) as m_l2a_a,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc), 0) as m_a2m_a,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc), 0) as pc_o2l_a,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc), 0) as pc_l2a_a,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc), 0) as pc_a2m_a,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc) filter (where api_change = 'yes'), 0) as m_o2l_y,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc) filter (where api_change = 'yes'), 0) as m_l2a_y,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc) filter (where api_change = 'yes'), 0) as m_a2m_y,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc) filter (where api_change = 'yes'), 0) as pc_o2l_y,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc) filter (where api_change = 'yes'), 0) as pc_l2a_y,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc) filter (where api_change = 'yes'), 0) as pc_a2m_y,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc) filter (where api_change = 'no'), 0) as m_o2l_n,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc) filter (where api_change = 'no'), 0) as m_l2a_n,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc) filter (where api_change = 'no'), 0) as m_a2m_n,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc) filter (where api_change = 'no'), 0) as pc_o2l_n,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc) filter (where api_change = 'no'), 0) as pc_l2a_n,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc) filter (where api_change = 'no'), 0) as pc_a2m_n
from
  tdiffs_groups t,
  gha_issues_events_labels iel
where
  t.issue_id = iel.issue_id
  and iel.label_name like 'size/%'
group by
  repo_group,
  iel.label_name
union select
  'tmet;All_All_' || substring(ielk.label_name from 6) || ';'
  || 'amedo2l,amedl2a,ameda2m,ap85o2l,ap85l2a,ap85a2m,'
  || 'ymedo2l,ymedl2a,ymeda2m,yp85o2l,yp85l2a,yp85a2m,'
  || 'nmedo2l,nmedl2a,nmeda2m,np85o2l,np85l2a,np85a2m'
  as name,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc), 0) as m_o2l_a,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc), 0) as m_l2a_a,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc), 0) as m_a2m_a,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc), 0) as pc_o2l_a,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc), 0) as pc_l2a_a,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc), 0) as pc_a2m_a,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc) filter (where api_change = 'yes'), 0) as m_o2l_y,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc) filter (where api_change = 'yes'), 0) as m_l2a_y,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc) filter (where api_change = 'yes'), 0) as m_a2m_y,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc) filter (where api_change = 'yes'), 0) as pc_o2l_y,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc) filter (where api_change = 'yes'), 0) as pc_l2a_y,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc) filter (where api_change = 'yes'), 0) as pc_a2m_y,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc) filter (where api_change = 'no'), 0) as m_o2l_n,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc) filter (where api_change = 'no'), 0) as m_l2a_n,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc) filter (where api_change = 'no'), 0) as m_a2m_n,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc) filter (where api_change = 'no'), 0) as pc_o2l_n,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc) filter (where api_change = 'no'), 0) as pc_l2a_n,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc) filter (where api_change = 'no'), 0) as pc_a2m_n
from
  tdiffs t,
  gha_issues_events_labels ielk
where
  t.issue_id = ielk.issue_id
  and ielk.label_name in ('kind/bug', 'kind/feature', 'kind/design', 'kind/cleanup', 'kind/documentation', 'kind/flake', 'kind/kep')
group by
  ielk.label_name
union select 'tmet;' || repo_group || '_All_' || substring(ielk.label_name from 6) || ';'
  || 'amedo2l,amedl2a,ameda2m,ap85o2l,ap85l2a,ap85a2m,'
  || 'ymedo2l,ymedl2a,ymeda2m,yp85o2l,yp85l2a,yp85a2m,'
  || 'nmedo2l,nmedl2a,nmeda2m,np85o2l,np85l2a,np85a2m'
  as name,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc), 0) as m_o2l_a,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc), 0) as m_l2a_a,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc), 0) as m_a2m_a,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc), 0) as pc_o2l_a,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc), 0) as pc_l2a_a,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc), 0) as pc_a2m_a,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc) filter (where api_change = 'yes'), 0) as m_o2l_y,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc) filter (where api_change = 'yes'), 0) as m_l2a_y,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc) filter (where api_change = 'yes'), 0) as m_a2m_y,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc) filter (where api_change = 'yes'), 0) as pc_o2l_y,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc) filter (where api_change = 'yes'), 0) as pc_l2a_y,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc) filter (where api_change = 'yes'), 0) as pc_a2m_y,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc) filter (where api_change = 'no'), 0) as m_o2l_n,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc) filter (where api_change = 'no'), 0) as m_l2a_n,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc) filter (where api_change = 'no'), 0) as m_a2m_n,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc) filter (where api_change = 'no'), 0) as pc_o2l_n,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc) filter (where api_change = 'no'), 0) as pc_l2a_n,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc) filter (where api_change = 'no'), 0) as pc_a2m_n
from
  tdiffs_groups t,
  gha_issues_events_labels ielk
where
  t.issue_id = ielk.issue_id
  and ielk.label_name in ('kind/bug', 'kind/feature', 'kind/design', 'kind/cleanup', 'kind/documentation', 'kind/flake', 'kind/kep')
group by
  repo_group,
  ielk.label_name
union select 'tmet;All_' || substring(iel.label_name from 6) || '_' || substring(ielk.label_name from 6) || ';'
  || 'amedo2l,amedl2a,ameda2m,ap85o2l,ap85l2a,ap85a2m,'
  || 'ymedo2l,ymedl2a,ymeda2m,yp85o2l,yp85l2a,yp85a2m,'
  || 'nmedo2l,nmedl2a,nmeda2m,np85o2l,np85l2a,np85a2m'
  as name,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc), 0) as m_o2l_a,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc), 0) as m_l2a_a,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc), 0) as m_a2m_a,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc), 0) as pc_o2l_a,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc), 0) as pc_l2a_a,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc), 0) as pc_a2m_a,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc) filter (where api_change = 'yes'), 0) as m_o2l_y,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc) filter (where api_change = 'yes'), 0) as m_l2a_y,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc) filter (where api_change = 'yes'), 0) as m_a2m_y,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc) filter (where api_change = 'yes'), 0) as pc_o2l_y,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc) filter (where api_change = 'yes'), 0) as pc_l2a_y,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc) filter (where api_change = 'yes'), 0) as pc_a2m_y,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc) filter (where api_change = 'no'), 0) as m_o2l_n,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc) filter (where api_change = 'no'), 0) as m_l2a_n,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc) filter (where api_change = 'no'), 0) as m_a2m_n,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc) filter (where api_change = 'no'), 0) as pc_o2l_n,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc) filter (where api_change = 'no'), 0) as pc_l2a_n,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc) filter (where api_change = 'no'), 0) as pc_a2m_n
from
  tdiffs t,
  gha_issues_events_labels iel,
  gha_issues_events_labels ielk
where
  t.issue_id = iel.issue_id
  and iel.label_name like 'size/%'
  and t.issue_id = ielk.issue_id
  and ielk.label_name in ('kind/bug', 'kind/feature', 'kind/design', 'kind/cleanup', 'kind/documentation', 'kind/flake', 'kind/kep') 
group by
  iel.label_name,
  ielk.label_name
union select 'tmet;' || repo_group || '_' || substring(iel.label_name from 6) || '_' || substring(ielk.label_name from 6) || ';'
  || 'amedo2l,amedl2a,ameda2m,ap85o2l,ap85l2a,ap85a2m,'
  || 'ymedo2l,ymedl2a,ymeda2m,yp85o2l,yp85l2a,yp85a2m,'
  || 'nmedo2l,nmedl2a,nmeda2m,np85o2l,np85l2a,np85a2m'
  as name,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc), 0) as m_o2l_a,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc), 0) as m_l2a_a,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc), 0) as m_a2m_a,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc), 0) as pc_o2l_a,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc), 0) as pc_l2a_a,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc), 0) as pc_a2m_a,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc) filter (where api_change = 'yes'), 0) as m_o2l_y,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc) filter (where api_change = 'yes'), 0) as m_l2a_y,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc) filter (where api_change = 'yes'), 0) as m_a2m_y,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc) filter (where api_change = 'yes'), 0) as pc_o2l_y,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc) filter (where api_change = 'yes'), 0) as pc_l2a_y,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc) filter (where api_change = 'yes'), 0) as pc_a2m_y,
  greatest(percentile_disc(0.5) within group (order by open_to_lgtm asc) filter (where api_change = 'no'), 0) as m_o2l_n,
  greatest(percentile_disc(0.5) within group (order by lgtm_to_approve asc) filter (where api_change = 'no'), 0) as m_l2a_n,
  greatest(percentile_disc(0.5) within group (order by approve_to_merge asc) filter (where api_change = 'no'), 0) as m_a2m_n,
  greatest(percentile_disc(0.85) within group (order by open_to_lgtm asc) filter (where api_change = 'no'), 0) as pc_o2l_n,
  greatest(percentile_disc(0.85) within group (order by lgtm_to_approve asc) filter (where api_change = 'no'), 0) as pc_l2a_n,
  greatest(percentile_disc(0.85) within group (order by approve_to_merge asc) filter (where api_change = 'no'), 0) as pc_a2m_n
from
  tdiffs_groups t,
  gha_issues_events_labels iel,
  gha_issues_events_labels ielk
where
  t.issue_id = iel.issue_id
  and iel.label_name like 'size/%'
  and t.issue_id = ielk.issue_id
  and ielk.label_name in ('kind/bug', 'kind/feature', 'kind/design', 'kind/cleanup', 'kind/documentation', 'kind/flake', 'kind/kep')
group by
  repo_group,
  iel.label_name,
  ielk.label_name
order by
  name asc
;
