with prs as (
  select pr.id,
    pr.dup_repo_id as repo_id,
    pr.dup_repo_name as repo_name,
    pr.created_at,
    pr.merged_at,
    pr.event_id
  from
    gha_pull_requests pr
  where
    pr.created_at >= '{{from}}'
    and pr.created_at < '{{to}}'
    and pr.event_id = (
      select s.event_id from gha_pull_requests s where s.id = pr.id order by s.updated_at desc limit 1
    )
), prs_labels as (
  select distinct pr.id,
    pr.repo_id,
    pr.repo_name,
    iel.label_name,
    pr.created_at,
    pr.merged_at,
    pr.event_id as pr_event_id
  from
    prs pr,
    gha_issues_pull_requests ipr,
    gha_issues_events_labels iel
  where
    pr.id = ipr.pull_request_id
    and pr.repo_id = ipr.repo_id
    and pr.repo_name = ipr.repo_name
    and ipr.issue_id = iel.issue_id
    and iel.label_name in ('kind/api-change', 'kind/bug', 'kind/feature', 'kind/design', 'kind/cleanup', 'kind/documentation', 'kind/flake', 'kind/kep')
    and iel.created_at >= '{{from}}'
    and iel.created_at < '{{to}}'
    and ipr.created_at >= '{{from}}'
    and ipr.created_at < '{{to}}'
), prs_groups as (
  select distinct sub.repo,
    sub.id,
    sub.created_at,
    sub.merged_at
  from (
    select pr.repo_name as repo,
      pr.id,
      pr.created_at,
      pr.merged_at
    from
      prs pr
    where
      pr.created_at >= '{{from}}'
      and pr.created_at < '{{to}}'
      and pr.repo_name in (select repo_name from trepos)
    ) sub
), prs_groups_labels as (
  select distinct sub.repo,
    sub.label_name,
    sub.id,
    sub.created_at,
    sub.merged_at
  from (
    select pr.repo_name as repo,
      pr.id,
      pr.label_name,
      pr.created_at,
      pr.merged_at
    from
      prs_labels pr
    where
      pr.created_at >= '{{from}}'
      and pr.created_at < '{{to}}'
      and pr.repo_name in (select repo_name from trepos)
    ) sub
), tdiffs as (
  select id,
    extract(epoch from coalesce(merged_at - created_at, now() - created_at)) / 3600 as age
  from
    prs
), tdiffs_groups as (
  select id,
    repo,
    extract(epoch from coalesce(merged_at - created_at, now() - created_at)) / 3600 as age
  from
    prs_groups
), tdiffs_labels as (
  select id,
    substring(label_name from 6) as label,
    extract(epoch from coalesce(merged_at - created_at, now() - created_at)) / 3600 as age
  from
    prs_labels
), tdiffs_groups_labels as (
  select id,
    repo,
    substring(label_name from 6) as label,
    extract(epoch from coalesce(merged_at - created_at, now() - created_at)) / 3600 as age
  from
    prs_groups_labels
)
select
  'prs_age;All,All;n,m' as name,
  round(count(distinct id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by age asc) as age_median
from
  tdiffs
union select 'prs_age;' || repo || ',All;n,m' as name,
  round(count(distinct id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by age asc) as age_median
from
  tdiffs_groups
group by
  repo
union select
  'prs_age;All,' || label || ';n,m' as name,
  round(count(distinct id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by age asc) as age_median
from
  tdiffs_labels
group by
  label
union select 'prs_age;' || repo || ',' || label || ';n,m' as name,
  round(count(distinct id) / {{n}}, 2) as num,
  percentile_disc(0.5) within group (order by age asc) as age_median
from
  tdiffs_groups_labels
group by
  label,
  repo
order by
  num desc,
  name asc
;
