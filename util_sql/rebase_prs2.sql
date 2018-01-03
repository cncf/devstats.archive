create temp table issues as
select i.id,
  i.number,
  i.dup_repo_name,
  min(pr.created_at) as created,
  max(pr.closed_at) as closed
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
  and pr.created_at < '{{to}}'
group by
  i.id,
  i.number,
  i.dup_repo_name
;

create temp table rebases as
select il.issue_id,
  i.number,
  i.dup_repo_name,
  max(il.dup_created_at) as rebase_dt
from
  issues i,
  gha_issues_labels il
where
  il.issue_id = i.id
  and il.dup_label_name = 'needs-rebase'
  and il.dup_created_at >= i.created
  and il.dup_created_at < '{{to}}'
  and (
    i.closed is null
    or (
      il.dup_created_at <= i.closed
      and i.closed >= '{{to}}'
    )
  )
group by
  il.issue_id,
  i.number,
  i.dup_repo_name
;

create temp table removed_rebases as
select il.issue_id,
  r.number,
  r.dup_repo_name,
  min(il.dup_created_at) as removed_dt
from
  gha_issues_labels il,
  rebases r
where
  r.issue_id = il.issue_id
  and il.dup_created_at > r.rebase_dt
  and il.dup_created_at < '{{to}}'
group by
  il.issue_id,
  r.number,
  r.dup_repo_name
;

select
  -- count(distinct r.number) as need_rebase_count
  r.dup_repo_name,
  r.number,
  r.issue_id,
  to_char(r.rebase_dt, 'YYYY-MM-DD HH24:MI:SS')
from
  rebases r
left join
  removed_rebases rr
on
  r.issue_id = rr.issue_id
where
  rr.issue_id is null
;

drop table removed_rebases;
drop table rebases;
drop table issues;
