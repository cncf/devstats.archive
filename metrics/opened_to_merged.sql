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

create temp table tdiffs as
select extract(epoch from merged_at - created_at) / 3600 as open_to_merge
from prs;

create temp table tdiffs_groups as
select repo_group, extract(epoch from merged_at - created_at) / 3600 as open_to_merge
from prs_groups;

select
  'opened_to_merged;All;percentile_15,median,percentile_85' as name,
  percentile_disc(0.15) within group (order by open_to_merge asc) as open_to_merge_15_percentile,
  percentile_disc(0.5) within group (order by open_to_merge asc) as open_to_merge_median,
  percentile_disc(0.85) within group (order by open_to_merge asc) as open_to_merge_85_percentile
from
  tdiffs_groups
union select 'opened_to_merged;' || repo_group || ';percentile_15,median,percentile_85' as name,
  percentile_disc(0.15) within group (order by open_to_merge asc) as open_to_merge_15_percentile,
  percentile_disc(0.5) within group (order by open_to_merge asc) as open_to_merge_median,
  percentile_disc(0.85) within group (order by open_to_merge asc) as open_to_merge_85_percentile
from
  tdiffs_groups
group by
  repo_group
;

drop table tdiffs_groups;
drop table prs_groups;
drop table tdiffs;
drop table prs;
