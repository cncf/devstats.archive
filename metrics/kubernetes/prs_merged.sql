select
  'prs_merged,' || r.alias as repo_name,
  round(count(distinct pr.id) / {{n}}, 2) as merge_count
from
  gha_pull_requests pr,
  gha_repos r
where
  r.name = pr.dup_repo_name
  and pr.merged_at is not null
  and pr.merged_at >= '{{from}}'
  and pr.merged_at < '{{to}}'
group by
  r.alias
order by
  merge_count desc
;
