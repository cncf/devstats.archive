create temp table issues as
select i.id,
  min(i.created_at) as created,
  max(i.closed_at) as closed
from
  gha_issues_pull_requests ipr,
  gha_pull_requests pr,
  gha_issues i
where
  ipr.issue_id = i.id
  and ipr.pull_request_id = pr.id
  and i.number = pr.number
  and i.dup_repo_id = pr.dup_repo_id
  and i.is_pull_request = true
  and i.created_at >= '{{from}}'
  and i.created_at < '{{to}}'
group by
  i.id
;

create temp table rebases as
select distinct i.id
from
  issues i,
  gha_issues_labels il
where
  il.issue_id = i.id
  and il.dup_label_name = 'needs-rebase'
  and il.dup_created_at >= i.created
  and (
    i.closed is null
    or il.dup_created_at < i.closed
  )
;

select
  round(count(distinct id) / {{n}}, 2) as need_rebase_count
from
  rebases
;

drop table rebases;
drop table issues;
