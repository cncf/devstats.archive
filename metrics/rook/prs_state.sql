create temp table all_prs as
select distinct i.id,
  i.dup_repo_name
from
  gha_issues i,
  gha_issues_pull_requests ipr,
  gha_pull_requests pr
where
  ipr.issue_id = i.id
  and ipr.pull_request_id = pr.id
  and i.number = pr.number
  and i.dup_repo_id = pr.dup_repo_id
  and i.is_pull_request = true
  and i.updated_at >= '{{from}}'
  and i.updated_at < '{{to}}'
  and (
    pr.merged_at is not null
    or pr.closed_at is null
  )
;

create temp table approved_prs as
select distinct i.id,
  i.dup_repo_name
from
  gha_issues i,
  gha_comments c,
  gha_issues_pull_requests ipr,
  gha_pull_requests pr
where
  ipr.issue_id = i.id
  and ipr.pull_request_id = pr.id
  and i.number = pr.number
  and i.dup_repo_id = pr.dup_repo_id
  and i.event_id = c.event_id
  and i.is_pull_request = true
  and i.updated_at >= '{{from}}'
  and i.updated_at < '{{to}}'
  and (
    pr.merged_at is not null
    or (
      pr.closed_at is null
      and substring(c.body from '(?i)(?:^|\n|\r)\s*/(approve|lgtm)\s*(?:\n|\r|$)') is not null
  )
 )
;

select
  'prs_approve_state;All;approved,awaiting' as name,
  round(count(distinct prs.id) filter (where a.id is not null) / {{n}}, 2) as approved,
  round(count(distinct prs.id) filter (where a.id is null) / {{n}}, 2) as awaiting
from
  all_prs prs
left join 
  approved_prs a
on
  prs.id = a.id
union select 'prs_approve_state;' || r.repo_group ||';approved,awaiting' as name,
  round(count(distinct prs.id) filter (where a.id is not null) / {{n}}, 2) as approved,
  round(count(distinct prs.id) filter (where a.id is null) / {{n}}, 2) as awaiting
from
  gha_repos r
join
  all_prs prs
on
  prs.dup_repo_name = r.name
  and r.repo_group is not null
left join 
  approved_prs a
on
  prs.id = a.id
group by
  r.repo_group
order by
  approved desc,
  awaiting desc,
  name asc
;

drop table all_prs;
drop table approved_prs;
