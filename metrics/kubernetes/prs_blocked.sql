with issues as (
  select distinct i.id as issue_id,
    pr.id as pr_id,
    pr.event_id as event_id,
    i.dup_repo_name
  from
    gha_issues_pull_requests ipr,
    gha_pull_requests pr,
    gha_issues i
  where
    i.is_pull_request = true
    and i.id = ipr.issue_id
    and ipr.pull_request_id = pr.id
    and i.number = pr.number
    and i.dup_repo_id = pr.dup_repo_id
    and i.created_at >= '{{from}}'
    and i.created_at < '{{to}}'
    and (pr.merged_at is null or pr.merged_at >= '{{to}}')
    and (pr.closed_at is null or pr.closed_at >= '{{to}}')
    and (i.closed_at is null or i.closed_at >= '{{to}}')
), issues_labels as (
  select 'All' as repo_group,
    round(count(distinct i.pr_id) / {{n}}, 2) as all_prs,
    round(count(distinct i.pr_id) filter (where il.dup_label_name = 'needs-ok-to-test') / {{n}}, 2) as needs_ok_to_test,
    round(count(distinct i.pr_id) filter (where il.dup_label_name = 'release-note-label-needed') / {{n}}, 2) as release_note_label_needed,
    round(count(distinct i.pr_id) filter (where il.dup_label_name = 'lgtm') / {{n}}, 2) as lgtm,
    round(count(distinct i.pr_id) filter (where il.dup_label_name = 'approved') / {{n}}, 2) as approved,
    round(count(distinct i.pr_id) filter (where il.dup_label_name like 'do-not-merge%') / {{n}}, 2) as do_not_merge
  from
    issues i
  left join
    gha_issues_labels il
  on
    il.issue_id = i.issue_id
    and il.dup_created_at >= '{{from}}'
    and il.dup_created_at < '{{to}}'
    and (
      il.dup_label_name in (
        'needs-ok-to-test', 'release-note-label-needed', 'lgtm', 'approved'
      )
      or il.dup_label_name like 'do-not-merge%'
    )
  union select sub.repo_group,
    round(count(distinct sub.pr_id) / {{n}}, 2) as all_prs,
    round(count(distinct sub.pr_id) filter (where sub.dup_label_name = 'needs-ok-to-test') / {{n}}, 2) as needs_ok_to_test,
    round(count(distinct sub.pr_id) filter (where sub.dup_label_name = 'release-note-label-needed') / {{n}}, 2) as release_note_label_needed,
    round(count(distinct sub.pr_id) filter (where sub.dup_label_name = 'lgtm') / {{n}}, 2) as lgtm,
    round(count(distinct sub.pr_id) filter (where sub.dup_label_name = 'approved') / {{n}}, 2) as approved,
    round(count(distinct sub.pr_id) filter (where sub.dup_label_name like 'do-not-merge%') / {{n}}, 2) as do_not_merge
  from (
    select coalesce(ecf.repo_group, r.repo_group) as repo_group,
      i.pr_id,
      il.dup_label_name
    from
      gha_repos r
    join
      issues i
    on
      i.dup_repo_name = r.name
    left join
      gha_events_commits_files ecf
    on
      ecf.event_id = i.event_id
    left join
      gha_issues_labels il
    on
      il.issue_id = i.issue_id
      and il.dup_created_at >= '{{from}}'
      and il.dup_created_at < '{{to}}'
      and (
        il.dup_label_name in (
          'needs-ok-to-test', 'release-note-label-needed', 'lgtm', 'approved'
        )
        or il.dup_label_name like 'do-not-merge%'
      )
    ) sub
  where
    sub.repo_group is not null
  group by
    sub.repo_group
)
select
  'prblck;' || repo_group ||';all,needs_ok_to_test,release_note_label_needed,no_lgtm,no_approve,do_not_merge' as name,
  all_prs,
  needs_ok_to_test,
  release_note_label_needed,
  all_prs - lgtm as no_lgtm,
  all_prs - approved as no_approve,
  do_not_merge
from
  issues_labels
order by
  all_prs desc,
  name asc
;
