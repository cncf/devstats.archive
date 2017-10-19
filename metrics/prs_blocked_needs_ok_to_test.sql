create temp table issues as
select distinct i.id as issue_id,
  pr.id as pr_id,
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
;

select
  'prs_blocked;All;all,needs_ok_to_test,release_note_label_needed,no_lgtm,no_approve,do_not_merge' as name,
  count(distinct i.pr_id) as all_prs,
  round(count(distinct i.pr_id) filter (where il_nott.issue_id is null) / {{n}}, 2) as needs_ok_to_test,
  round(count(distinct i.pr_id) filter (where il_rn.issue_id is null) / {{n}}, 2) as release_note_label_needed,
  round(count(distinct i.pr_id) filter (where il_lgtm.issue_id is null) / {{n}}, 2) as no_lgtm,
  round(count(distinct i.pr_id) filter (where il_ap.issue_id is null) / {{n}}, 2) as no_approve,
  round(count(distinct i.pr_id) filter (where il_dnm.issue_id is not null) / {{n}}, 2) as do_not_merge
from
  issues i
left join
  gha_issues_labels il_nott
on
  il_nott.issue_id = i.issue_id
  and il_nott.dup_created_at >= '{{from}}'
  and il_nott.dup_created_at < '{{to}}'
  and il_nott.dup_label_name = 'needs-ok-to-test'
left join
  gha_issues_labels il_rn
on
  il_rn.issue_id = i.issue_id
  and il_rn.dup_created_at >= '{{from}}'
  and il_rn.dup_created_at < '{{to}}'
  and il_rn.dup_label_name = 'release-note-label-needed'
left join
  gha_issues_labels il_lgtm
on
  il_lgtm.issue_id = i.issue_id
  and il_lgtm.dup_created_at >= '{{from}}'
  and il_lgtm.dup_created_at < '{{to}}'
  and il_lgtm.dup_label_name = 'lgtm'
left join
  gha_issues_labels il_ap
on
  il_ap.issue_id = i.issue_id
  and il_ap.dup_created_at >= '{{from}}'
  and il_ap.dup_created_at < '{{to}}'
  and il_ap.dup_label_name = 'approved'
left join
  gha_issues_labels il_dnm
on
  il_dnm.issue_id = i.issue_id
  and il_dnm.dup_created_at >= '{{from}}'
  and il_dnm.dup_created_at < '{{to}}'
  and il_dnm.dup_label_name like 'do-not-merge%'
union select 'prs_blocked;' || r.repo_group ||';all,needs_ok_to_test,release_note_label_needed,no_lgtm,no_approve,do_not_merge' as name,
  count(distinct i.pr_id) as all_prs,
  round(count(distinct i.pr_id) filter (where il_nott.issue_id is null) / {{n}}, 2) as needs_ok_to_test,
  round(count(distinct i.pr_id) filter (where il_rn.issue_id is null) / {{n}}, 2) as release_note_label_needed,
  round(count(distinct i.pr_id) filter (where il_lgtm.issue_id is null) / {{n}}, 2) as no_lgtm,
  round(count(distinct i.pr_id) filter (where il_ap.issue_id is null) / {{n}}, 2) as no_approve,
  round(count(distinct i.pr_id) filter (where il_dnm.issue_id is not null) / {{n}}, 2) as do_not_merge
from
  issues i
join
  gha_repos r
on
  i.dup_repo_name = r.name
  and r.repo_group is not null
left join
  gha_issues_labels il_nott
on
  il_nott.issue_id = i.issue_id
  and il_nott.dup_created_at >= '{{from}}'
  and il_nott.dup_created_at < '{{to}}'
  and il_nott.dup_label_name = 'needs-ok-to-test'
left join
  gha_issues_labels il_rn
on
  il_rn.issue_id = i.issue_id
  and il_rn.dup_created_at >= '{{from}}'
  and il_rn.dup_created_at < '{{to}}'
  and il_rn.dup_label_name = 'release-note-label-needed'
left join
  gha_issues_labels il_lgtm
on
  il_lgtm.issue_id = i.issue_id
  and il_lgtm.dup_created_at >= '{{from}}'
  and il_lgtm.dup_created_at < '{{to}}'
  and il_lgtm.dup_label_name = 'lgtm'
left join
  gha_issues_labels il_ap
on
  il_ap.issue_id = i.issue_id
  and il_ap.dup_created_at >= '{{from}}'
  and il_ap.dup_created_at < '{{to}}'
  and il_ap.dup_label_name = 'approved'
left join
  gha_issues_labels il_dnm
on
  il_dnm.issue_id = i.issue_id
  and il_dnm.dup_created_at >= '{{from}}'
  and il_dnm.dup_created_at < '{{to}}'
  and il_dnm.dup_label_name like 'do-not-merge%'
group by
  r.repo_group
order by
  all_prs desc,
  name asc
;

drop table issues;
