with prs_latest as (
  select sub.id,
    sub.event_id,
    sub.created_at,
    sub.merged_at,
    sub.dup_repo_id,
    sub.dup_repo_name
  from (
    select id,
      event_id,
      created_at,
      merged_at,
      dup_repo_id,
      dup_repo_name,
      row_number() over (partition by id order by updated_at desc, event_id desc) as rank
    from
      gha_pull_requests
    where
      created_at >= '{{from}}'
      and created_at < '{{to}}'
      and merged_at is not null
      and dup_repo_name in (select repo_name from trepos)
  ) sub
  where
    sub.rank = 1
), prs as (
  select ipr.issue_id,
    pr.created_at,
    pr.merged_at,
    case iel.label_name when 'kind/api-change' then 'yes' else 'no' end as api_change
  from
    prs_latest pr
  join
    gha_issues_pull_requests ipr
  on
    pr.id = ipr.pull_request_id
  left join
    gha_issues_events_labels iel
  on
    ipr.issue_id = iel.issue_id
    and iel.label_name = 'kind/api-change'
), prs_groups as (
  select sub.repo,
    sub.issue_id,
    sub.created_at,
    sub.merged_at,
    sub.api_change
  from (
    select pr.dup_repo_name as repo,
      ipr.issue_id,
      pr.created_at,
      pr.merged_at,
      case iel.label_name when 'kind/api-change' then 'yes' else 'no' end as api_change
    from
      prs_latest pr
    join
      gha_issues_pull_requests ipr
    on
      pr.dup_repo_id = ipr.repo_id
      and pr.dup_repo_name = ipr.repo_name
      and pr.id = ipr.pull_request_id
    left join
      gha_issues_events_labels iel
    on
      ipr.issue_id = iel.issue_id
      and iel.label_name = 'kind/api-change'
    ) sub
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
    pr_lgtm lgtm
  on
    prs.issue_id = lgtm.issue_id
  left join
    pr_approve approve
  on
    prs.issue_id = approve.issue_id
), ranges_groups as (
  select prs_groups.issue_id,
    prs_groups.repo as repo,
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
    repo,
    api_change,
    extract(epoch from coalesce(lgtm - open, approve - open, merge - open)) / 3600 as open_to_lgtm,
    extract(epoch from coalesce(approve - lgtm, merge - lgtm, '0'::interval)) / 3600 as lgtm_to_approve,
    extract(epoch from coalesce(merge - approve, '0'::interval)) / 3600 as approve_to_merge
  from
    ranges_groups
), labels as (
  select distinct issue_id,
    label_name,
    substring(label_name from 6) as label_sub_name
  from
    gha_issues_events_labels
  where
    issue_id in (select issue_id from prs)
    and (
      label_name in ('kind/bug', 'kind/feature', 'kind/design', 'kind/cleanup', 'kind/documentation', 'kind/flake', 'kind/kep')
      or label_name like 'size/%'
    )
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
union select 'tmet;' || repo || '_All_All;'
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
  repo
union select 'tmet;All_' || iel.label_sub_name || '_All;'
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
  labels iel
where
  t.issue_id = iel.issue_id
  and iel.label_name like 'size/%'
group by
  iel.label_sub_name
union select 'tmet;' || repo || '_' || iel.label_sub_name || '_All;'
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
  labels iel
where
  t.issue_id = iel.issue_id
  and iel.label_name like 'size/%'
group by
  repo,
  iel.label_sub_name
union select
  'tmet;All_All_' || ielk.label_sub_name || ';'
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
  labels ielk
where
  t.issue_id = ielk.issue_id
  and ielk.label_name in ('kind/bug', 'kind/feature', 'kind/design', 'kind/cleanup', 'kind/documentation', 'kind/flake', 'kind/kep')
group by
  ielk.label_sub_name
union select 'tmet;' || repo || '_All_' || ielk.label_sub_name || ';'
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
  labels ielk
where
  t.issue_id = ielk.issue_id
  and ielk.label_name in ('kind/bug', 'kind/feature', 'kind/design', 'kind/cleanup', 'kind/documentation', 'kind/flake', 'kind/kep')
group by
  repo,
  ielk.label_sub_name
union select 'tmet;All_' || iel.label_sub_name || '_' || ielk.label_sub_name || ';'
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
  labels iel,
  labels ielk
where
  t.issue_id = iel.issue_id
  and iel.label_name like 'size/%'
  and t.issue_id = ielk.issue_id
  and ielk.label_name in ('kind/bug', 'kind/feature', 'kind/design', 'kind/cleanup', 'kind/documentation', 'kind/flake', 'kind/kep') 
group by
  iel.label_sub_name,
  ielk.label_sub_name
union select 'tmet;' || repo || '_' || iel.label_sub_name || '_' || ielk.label_sub_name || ';'
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
  labels iel,
  labels ielk
where
  t.issue_id = iel.issue_id
  and iel.label_name like 'size/%'
  and t.issue_id = ielk.issue_id
  and ielk.label_name in ('kind/bug', 'kind/feature', 'kind/design', 'kind/cleanup', 'kind/documentation', 'kind/flake', 'kind/kep')
group by
  repo,
  iel.label_sub_name,
  ielk.label_sub_name
order by
  name asc
;
