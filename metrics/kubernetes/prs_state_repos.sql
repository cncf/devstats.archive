with all_prs as (
  select sub.id,
    sub.dup_repo_name,
    sub.dup_repo_id
  from (
    select distinct i.id,
      i.dup_repo_name,
      i.dup_repo_id,
      row_number() over (partition by i.id order by i.updated_at desc, i.event_id desc) as rank
    from
      gha_issues i,
      gha_issues_pull_requests ipr,
      gha_pull_requests pr
    where
      ipr.issue_id = i.id
      and ipr.pull_request_id = pr.id
      and i.number = pr.number
      and i.dup_repo_id = pr.dup_repo_id
      and i.dup_repo_name = pr.dup_repo_name
      and i.dup_repo_id = ipr.repo_id
      and i.dup_repo_name = ipr.repo_name
      and pr.dup_repo_id = ipr.repo_id
      and pr.dup_repo_name = ipr.repo_name
      and i.is_pull_request = true
      and i.updated_at >= '{{from}}'
      and i.updated_at < '{{to}}'
      and (
        pr.merged_at is not null
        or pr.closed_at is null
      )
  ) sub
  where
    sub.rank = 1
), approved_prs as (
  select distinct i.id,
    i.dup_repo_name,
    i.dup_repo_id
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
    and i.dup_repo_name = pr.dup_repo_name
    and i.dup_repo_id = ipr.repo_id
    and i.dup_repo_name = ipr.repo_name
    and pr.dup_repo_id = ipr.repo_id
    and pr.dup_repo_name = ipr.repo_name
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
)
select
  'pr_repappr;All;appr,wait' as name,
  round(count(distinct prs.id) filter (where a.id is not null) / {{n}}, 2) as approved,
  round(count(distinct prs.id) filter (where a.id is null) / {{n}}, 2) as awaiting
from
  all_prs prs
left join 
  approved_prs a
on
  prs.id = a.id
union select sub.name,
  round(count(distinct sub.id) filter (where sub.aid is not null) / {{n}}, 2) as approved,
  round(count(distinct sub.id) filter (where sub.aid is null) / {{n}}, 2) as awaiting
from (
  select 'pr_repappr;' || prs.dup_repo_name ||';appr,wait' as name,
    prs.id,
    a.id as aid
  from
    all_prs prs
  left join 
    approved_prs a
  on
    prs.id = a.id
  where
    prs.dup_repo_name in (select repo_name from trepos)
  ) sub
where
  sub.name is not null
group by
  sub.name
order by
  approved desc,
  awaiting desc,
  name asc
;
