select
  -- string_agg(sub3.sig, ',')
  sub3.sig
from (
  select sub2.sig,
    count(distinct sub2.issue_id) as cnt
  from (
    select case sub.sig
        when 'aws' then 'cloud-provider'
        when 'azure' then 'cloud-provider'
        when 'batchd' then 'cloud-provider'
        when 'cloud-provider-aws' then 'cloud-provider'
        when 'gcp' then 'cloud-provider'
        when 'ibmcloud' then 'cloud-provider'
        when 'openstack' then 'cloud-provider'
        when 'vmware' then 'cloud-provider'
        else sub.sig
      end as sig,
      sub.issue_id
    from (
      select sel.sig as sig,
        sel.issue_id
      from (
        select distinct issue_id,
          lower(substring(dup_label_name from '(?i)sig/(.*)')) as sig
        from
          gha_issues_labels
        where
          dup_created_at > now() - '2 years'::interval
        ) sel
      where
        sel.sig is not null
        and sel.sig not in (
          'apimachinery', 'api-machiner', 'cloude-provider', 'nework',
          'scalability-proprosals', 'storge', 'ui-preview-reviewes',
          'cluster-fifecycle', 'rktnetes'
        )
        and sel.sig not like '%use-only-as-a-last-resort'
    ) sub
  ) sub2
  group by
    sub2.sig
  having
    count(distinct sub2.issue_id) > 30
) sub3
order by
  cnt desc,
  sub3.sig asc
limit {{lim}}
;
