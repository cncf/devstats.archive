with issues as (
  select distinct sub.issue_id,
    sub.repo,
    sub.event_id
  from (
    select distinct
      id as issue_id,
      last_value(dup_repo_name) over issues_ordered_by_update as repo,
      last_value(event_id) over issues_ordered_by_update as event_id
    from
      gha_issues
    where
      created_at >= '{{from}}'
      and created_at < '{{to}}'
      and is_pull_request = true
      and dup_repo_name in (select repo_name from trepos)
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
), prs as (
  select distinct i.issue_id,
    i.repo,
    i.event_id
  from (
    select distinct id as pr_id
    from
      gha_pull_requests
    where
      created_at >= '{{from}}'
      and created_at < '{{to}}'
      and event_id > 0
      and dup_repo_name in (select repo_name from trepos)
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
), pr_sigs as (
  select sub2.issue_id,
    sub2.repo,
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
      sub.repo,
      sub.sig
    from (
      select pr.issue_id,
        pr.repo,
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
)
select
  'sig_prs_open;' || s.sig || '`' || s.repo || ';prs' as metric,
  round(count(distinct s.issue_id) / {{n}}, 2) as open_prs
from
  pr_sigs s
group by
  s.sig,
  s.repo
;
