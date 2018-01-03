create temp table issues as
select i.id,
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
  -- and i.dup_repo_id in (select id from gha_repos where org_login = 'kubernetes')
group by
  i.id
;

create temp table rebases as
select il.issue_id,
  max(il.dup_created_at) as rebase_dt
from
  issues i,
  gha_issues_labels il
where
  il.issue_id = i.id
  and il.dup_label_name = 'needs-rebase'
  and il.dup_created_at >= i.created
  and i.closed is null
group by
  il.issue_id
;

create temp table removed_rebases as
select il.issue_id,
  min(il.dup_created_at) as removed_dt
from
  gha_issues_labels il,
  rebases r
where
  r.issue_id = il.issue_id
  and il.dup_created_at > r.rebase_dt
group by
  il.issue_id
;

select
  -- count(distinct r.issue_id) as need_rebase_count
  r.issue_id,
  to_char(r.rebase_dt, 'YYYY-MM-DD HH24:MI:SS'),
  to_char(rr.removed_dt, 'YYYY-MM-DD HH24:MI:SS')
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
