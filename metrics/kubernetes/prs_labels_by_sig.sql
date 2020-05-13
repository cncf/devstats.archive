with dtfrom as (
  select '{{to}}'::timestamp - '1 year'::interval as dtfrom
), issues as (
  select distinct sub.issue_id,
    sub.event_id
  from (
    select distinct
      id as issue_id,
      last_value(event_id) over issues_ordered_by_update as event_id,
      last_value(closed_at) over issues_ordered_by_update as closed_at
    from
      gha_issues,
      dtfrom
    where
      created_at >= dtfrom
      and created_at < '{{to}}'
      and updated_at < '{{to}}'
      and is_pull_request = true
    window
      issues_ordered_by_update as (
        partition by id
        order by
          updated_at asc,
          event_id asc
        range between current row
        and unbounded following
      )
    ) sub
    where
      sub.closed_at is null
), prs as (
  select distinct i.issue_id,
    i.event_id
  from (
    select distinct id as pr_id,
      last_value(closed_at) over prs_ordered_by_update as closed_at,
      last_value(merged_at) over prs_ordered_by_update as merged_at
    from
      gha_pull_requests,
      dtfrom
    where
      created_at >= dtfrom
      and created_at < '{{to}}'
      and updated_at < '{{to}}'
      and event_id > 0
    window
      prs_ordered_by_update as (
        partition by id
        order by
          updated_at asc,
          event_id asc
        range between current row
        and unbounded following
      )
    ) pr,
    issues i,
    gha_issues_pull_requests ipr
  where
    ipr.issue_id = i.issue_id
    and ipr.pull_request_id = pr.pr_id
    and pr.closed_at is null
    and pr.merged_at is null
), pr_sigs as (
  select sub2.issue_id,
    sub2.event_id,
    case sub2.sig
      when 'aws' then 'cloud-provider'
      when 'azure' then 'cloud-provider'
      when 'batchd' then 'cloud-provider'
      when 'cloud-provider-aws' then 'cloud-provider'
      when 'gcp' then 'cloud-provider'
      when 'ibmcloud' then 'cloud-provider'
      when 'openstack' then 'cloud-provider'
      when 'vmware' then 'cloud-provider'
      else sub2.sig
    end as sig
  from (
    select sub.issue_id,
      sub.event_id,
      sub.sig
    from (
      select pr.issue_id,
        pr.event_id,
        lower(substring(il.dup_label_name from '(?i)sig/(.*)')) as sig
      from
        gha_issues_labels il,
        prs pr
      where
        il.issue_id = pr.issue_id
        and il.event_id = pr.event_id
      ) sub
    where
      sub.sig is not null
      and sub.sig not in (
        'apimachinery', 'api-machiner', 'cloude-provider', 'nework',
        'scalability-proprosals', 'storge', 'ui-preview-reviewes',
        'cluster-fifecycle', 'rktnetes'
      )
      and sub.sig not like '%use-only-as-a-last-resort'
      and sub.sig in (select sig_mentions_labels_name from tsig_mentions_labels)
  ) sub2
), pr_labels as (
  select il.issue_id,
    il.event_id,
    il.dup_label_name as label
  from
    prs pr,
    gha_issues_labels il
  where
    il.issue_id = pr.issue_id
    and il.event_id = pr.event_id
    and il.dup_label_name in (
      'cla: no',
      'cncf-cla: no',
      'do-not-merge',
      'do-not-merge/blocked-paths',
      'do-not-merge/cherry-pick-not-approved',
      'do-not-merge/hold',
      'do-not-merge/release-note-label-needed',
      'do-not-merge/work-in-progress',
      'needs-ok-to-test',
      'needs-rebase',
      'needs-priority',
      'priority/critical-urgent',
      'release-note-label-needed'
    )
)
select
  sub.name,
  count(distinct sub.issue_id) as cnt
from (
  select 'prsiglbl,' || s.sig || ': All labels combined' as name,
    s.issue_id
  from
    pr_sigs s
  union select 'prsiglbl,' || s.sig || ': ' || l.label as name,
    l.issue_id
  from
    pr_sigs s,
    pr_labels l
  where
    s.event_id = l.event_id
  union select 'prsiglbl,All SIGs combined: All labels combined' as name,
    l.issue_id
  from
    pr_labels l
  union select 'prsiglbl,All SIGs combined: ' || l.label as name,
    l.issue_id
  from
    pr_labels l
  ) sub
where
  sub.name is not null
group by
  sub.name
order by
  cnt desc,
  name asc
;
