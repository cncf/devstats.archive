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

create temp table tdiffs as
select extract(epoch from prs.merged_at - prs.created_at) / 3600 as open_to_merge
from prs;

select
  'mono_opened_to_merged_percentile_15,mono_opened_to_merged_median,mono_opened_to_merged_percentile_85' as name,
  percentile_disc(0.15) within group (order by open_to_merge asc) as open_to_merge_15_percentile,
  percentile_disc(0.5) within group (order by open_to_merge asc) as open_to_merge_median,
  percentile_disc(0.85) within group (order by open_to_merge asc) as open_to_merge_85_percentile
from
  tdiffs;

drop table tdiffs;
drop table prs;
