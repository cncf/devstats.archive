create temp table issues as
select i.id as issue_id,
  i.event_id,
  i.updated_at
from
  gha_issues i
where
  i.is_pull_request = true
  and i.id > 0
  and i.event_id > 0
  and i.closed_at is null
  and i.created_at < '{{date}}'
  and i.event_id = (
    select inn.event_id
    from
      gha_issues inn
    where
      inn.id = i.id
      and inn.id > 0
      and inn.event_id > 0
      and inn.created_at < '{{date}}'
      and inn.is_pull_request = true
      and inn.updated_at < '{{date}}'
    order by
      inn.updated_at desc,
      inn.event_id desc
    limit
      1
  )
;

create temp table prs as
select i.issue_id,
  i.event_id as last_issue_event_id,
  i.updated_at as issue_last_updated,
  pr.id as pr_id,
  pr.event_id as last_pr_event_id,
  pr.updated_at as pr_last_updated
from
  issues i,
  gha_issues_pull_requests ipr,
  gha_pull_requests pr
where
  ipr.issue_id = i.issue_id
  and ipr.pull_request_id = pr.id
  and pr.id > 0
  and pr.event_id > 0
  and pr.closed_at is null
  and pr.merged_at is null
  and pr.created_at < '{{date}}'
  and pr.event_id = (
    select inn.event_id
    from
      gha_pull_requests inn
    where
      inn.id = pr.id
      and inn.id > 0
      and inn.event_id > 0
      and inn.created_at < '{{date}}'
      and inn.updated_at < '{{date}}'
    order by
      inn.updated_at desc,
      inn.event_id desc
    limit
      1
  )
order by
  i.updated_at desc,
  pr.updated_at desc
;

select * from prs;

drop table prs;
drop table issues;
