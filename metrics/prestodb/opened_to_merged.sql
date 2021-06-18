with prs as (
  select pr.created_at, pr.merged_at
  from
    gha_pull_requests pr
  where
    pr.merged_at is not null
    and pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
    and pr.event_id = (
      select i.event_id from gha_pull_requests i where i.id = pr.id order by i.updated_at desc limit 1
    )
), prs_groups as (
  select r.repo_group,
    pr.created_at,
    pr.merged_at as merged_at
  from
    gha_pull_requests pr,
    gha_repos r
  where
    r.id = pr.dup_repo_id
    and r.name = pr.dup_repo_name
    and r.repo_group is not null
    and pr.merged_at is not null
    and pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
    and pr.event_id = (
      select i.event_id from gha_pull_requests i where i.id = pr.id order by i.updated_at desc limit 1
    )
), prs_comps as (
  select
    aa.company_name,
    pr.created_at,
    pr.merged_at
  from
    gha_pull_requests pr,
    gha_actors_affiliations aa
  where
    aa.actor_id = pr.user_id
    and aa.dt_from <= pr.created_at
    and aa.dt_to > pr.created_at
    and aa.company_name in (select companies_name from tcompanies)
    and pr.merged_at is not null
    and pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
    and pr.event_id = (
      select i.event_id from gha_pull_requests i where i.id = pr.id order by i.updated_at desc limit 1
    )
), prs_groups_comps as (
  select r.repo_group,
    aa.company_name,
    pr.created_at,
    pr.merged_at as merged_at
  from
    gha_pull_requests pr,
    gha_repos r,
    gha_actors_affiliations aa
  where
    aa.actor_id = pr.user_id
    and aa.dt_from <= pr.created_at
    and aa.dt_to > pr.created_at
    and aa.company_name in (select companies_name from tcompanies)
    and r.id = pr.dup_repo_id
    and r.name = pr.dup_repo_name
    and r.repo_group is not null
    and pr.merged_at is not null
    and pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
    and pr.event_id = (
      select i.event_id from gha_pull_requests i where i.id = pr.id order by i.updated_at desc limit 1
    )
), tdiffs as (
  select extract(epoch from merged_at - created_at) / 3600 as open_to_merge
  from
    prs
), tdiffs_groups as (
  select repo_group, extract(epoch from merged_at - created_at) / 3600 as open_to_merge
  from
    prs_groups
), tdiffs_comps as (
  select company_name, extract(epoch from merged_at - created_at) / 3600 as open_to_merge
  from
    prs_comps
), tdiffs_groups_comps as (
  select repo_group, company_name, extract(epoch from merged_at - created_at) / 3600 as open_to_merge
  from
    prs_groups_comps
)
select
  'open2merge;All_All;p15,med,p85' as name,
  percentile_disc(0.15) within group (order by open_to_merge asc) as open_to_merge_15_percentile,
  percentile_disc(0.5) within group (order by open_to_merge asc) as open_to_merge_median,
  percentile_disc(0.85) within group (order by open_to_merge asc) as open_to_merge_85_percentile
from
  tdiffs
union select 'open2merge;' || repo_group || '_All;p15,med,p85' as name,
  percentile_disc(0.15) within group (order by open_to_merge asc) as open_to_merge_15_percentile,
  percentile_disc(0.5) within group (order by open_to_merge asc) as open_to_merge_median,
  percentile_disc(0.85) within group (order by open_to_merge asc) as open_to_merge_85_percentile
from
  tdiffs_groups
group by
  repo_group
union select 'open2merge;All_' || company_name || ';p15,med,p85' as name,
  percentile_disc(0.15) within group (order by open_to_merge asc) as open_to_merge_15_percentile,
  percentile_disc(0.5) within group (order by open_to_merge asc) as open_to_merge_median,
  percentile_disc(0.85) within group (order by open_to_merge asc) as open_to_merge_85_percentile
from
  tdiffs_comps
group by
  company_name
union select 'open2merge;' || repo_group || '_' || company_name || ';p15,med,p85' as name,
  percentile_disc(0.15) within group (order by open_to_merge asc) as open_to_merge_15_percentile,
  percentile_disc(0.5) within group (order by open_to_merge asc) as open_to_merge_median,
  percentile_disc(0.85) within group (order by open_to_merge asc) as open_to_merge_85_percentile
from
  tdiffs_groups_comps
group by
  repo_group,
  company_name
order by
  open_to_merge_median desc,
  name asc
;
