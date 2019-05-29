with issues as (
  select distinct id,
    dup_repo_name as repo,
    min(created_at) as created_at
  from
    gha_issues
  where
    is_pull_request = false
    and created_at >= '{{from}}'
    and created_at < '{{to}}'
  group by
    id,
    dup_repo_name
), issues_labels as (
  select count(distinct i.id) as all_issues,
     count(distinct i.id) filter (where il.issue_id is not null) as flaky_issues
  from
    issues i
  left join
    gha_issues_labels il
  on
    i.id = il.issue_id
    and il.dup_label_name = 'flaky-test'
)
select * from issues_labels;
