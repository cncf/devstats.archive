with issues as (
  select sub.issue_id,
    sub.event_id,
    sub.milestone_id,
    sub.repo
  from (
    select distinct
      id as issue_id,
      dup_repo_name as repo,
      last_value(closed_at) over issues_ordered_by_update as closed_at,
      last_value(event_id) over issues_ordered_by_update as event_id,
      last_value(milestone_id) over issues_ordered_by_update as milestone_id
    from
      gha_issues
    where
      created_at < '{{to}}'
      and updated_at < '{{to}}'
      and is_pull_request = false
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
), issues_sigs as (
  select sub2.issue_id,
    sub2.repo,
    case sub2.sig
      when 'aws' then 'cloud-provider'
      when 'azure' then 'cloud-provider'
      when 'batchd' then 'cloud-provider'
      when 'gcp' then 'cloud-provider'
      when 'ibmcloud' then 'cloud-provider'
      when 'openstack' then 'cloud-provider'
      when 'vmware' then 'cloud-provider'
      else sub2.sig
    end as sig
  from (
    select sub.issue_id,
      sub.repo,
      sub.sig
    from (
      select i.issue_id,
        i.repo,
        lower(substring(il.dup_label_name from '(?i)sig/(.*)')) as sig
      from
        issues i,
        gha_issues_labels il
      where
        i.event_id = il.event_id
        and i.issue_id = il.issue_id
    ) sub
    where
      sub.sig is not null
      and sub.sig not in (
        'apimachinery', 'api-machiner', 'cloude-provider', 'nework',
        'scalability-proprosals', 'storge', 'ui-preview-reviewes',
        'cluster-fifecycle', 'rktnetes'
      )
      and sub.sig not like '%use-only-as-a-last-resort'
  ) sub2
  where
    sub2.sig in (select sig_mentions_labels_name from tsig_mentions_labels)
), issues_milestones as (
  select i.issue_id,
    i.repo,
    ml.title as milestone
  from
    issues i,
    gha_milestones ml
  where
    i.milestone_id = ml.id
    and i.event_id = ml.event_id
)
select 
  sub.sig_milestone,
  sub.cnt
from (
  select concat('isigml,', s.sig, '-', m.milestone, '-', s.repo) as sig_milestone,
    count(s.issue_id) as cnt
  from
    issues_milestones m,
    issues_sigs s
  where
    m.issue_id = s.issue_id
  group by
    s.sig,
    m.milestone,
    s.repo
  union select concat('isigml,', 'All-', m.milestone, '-', m.repo) as sig_milestone,
    count(m.issue_id) as cnt
  from
    issues_milestones m
  group by
    m.milestone,
    m.repo
  union select concat('isigml,', s.sig, '-All-', s.repo) as sig_milestone,
    count(s.issue_id) as cnt
  from
    issues_sigs s
  group by
    s.sig,
    s.repo
  union select concat('isigml,All-All-', i.repo) as sig_milestone,
    count(i.issue_id) as cnt
  from
    issues i
  group by
    i.repo
  union select concat('isigml,', s.sig, '-', m.milestone, '-All') as sig_milestone,
    count(s.issue_id) as cnt
  from
    issues_milestones m,
    issues_sigs s
  where
    m.issue_id = s.issue_id
  group by
    s.sig,
    m.milestone
  union select concat('isigml,', 'All-', m.milestone, '-All') as sig_milestone,
    count(m.issue_id) as cnt
  from
    issues_milestones m
  group by
    m.milestone
  union select concat('isigml,', s.sig, '-All-All') as sig_milestone,
    count(s.issue_id) as cnt
  from
    issues_sigs s
  group by
    s.sig
  union select 'isigml,All-All-All' as sig_milestone,
    count(i.issue_id) as cnt
  from
    issues i
  ) sub
order by
  sub.cnt desc,
  sub.sig_milestone asc
;
