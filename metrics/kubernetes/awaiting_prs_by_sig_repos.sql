with dtfrom as (
  select '{{to}}'::timestamp - '3 year'::interval as dtfrom
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
), dtto as (
  select case '{{to}}'::timestamp > now() when true then now() else '{{to}}'::timestamp end as dtto
)
select
  'awaiting_prs_by_sig_repos;' || sub.sig || '`' || sub.repo || ';d10,d30,d60,d90,y' as metric,
  count(distinct sub.issue_id) filter(where sub.age > 864000) as open_10,
  count(distinct sub.issue_id) filter(where sub.age > 2592000) as open_30,
  count(distinct sub.issue_id) filter(where sub.age > 5184000) as open_60,
  count(distinct sub.issue_id) filter(where sub.age > 7776000) as open_90,
  count(distinct sub.issue_id) filter(where sub.age > 31557600) as open_y
from
  (
  select s.sig,
    pr.dup_repo_name as repo,
    s.issue_id,
    extract(epoch from d.dtto - pr.created_at) as age
  from
    pr_sigs s,
    gha_issues pr,
    dtto d
  where
    s.event_id = pr.event_id
    and pr.dup_repo_name in (select repo_name from trepos)
  ) sub
group by
  sub.sig,
  sub.repo
;
