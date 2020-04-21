select
  concat('iclosed_lsk,', sel1.sig, '-', sel2.kind) as sig_kind,
  round(count(distinct sel1.id) / {{n}}, 2) as cnt
from (
  select sub.id,
    case sub.sig
      when 'aws' then 'cloud-provider'
      when 'azure' then 'cloud-provider'
      when 'batchd' then 'cloud-provider'
      when 'cloud-provider-aws' then 'cloud-provider'
      when 'gcp' then 'cloud-provider'
      when 'ibmcloud' then 'cloud-provider'
      when 'openstack' then 'cloud-provider'
      when 'vmware' then 'cloud-provider'
      else sub.sig
    end as sig
  from (
    select distinct i.id,
      lower(substring(il.dup_label_name from '(?i)sig/(.*)')) as sig
    from
      gha_issues_labels il,
      gha_issues i
    where
      i.id = il.issue_id
      and i.closed_at >= '{{from}}'
      and i.closed_at < '{{to}}'
  ) sub
  where
    sub.sig not in (
      'apimachinery', 'api-machiner', 'cloude-provider', 'nework',
      'scalability-proprosals', 'storge', 'ui-preview-reviewes',
      'cluster-fifecycle', 'rktnetes'
    )
    and sub.sig not like '%use-only-as-a-last-resort'
  union select id,
    'All' as sig
  from
    gha_issues
  where
    closed_at >= '{{from}}'
    and closed_at < '{{to}}'
  ) sel1, (
  select distinct i.id,
    lower(substring(il.dup_label_name from '(?i)kind/(.*)')) as kind
  from
    gha_issues_labels il,
    gha_issues i
  where
    i.id = il.issue_id
    and i.closed_at >= '{{from}}'
    and i.closed_at < '{{to}}'
  union select id,
    'All' as kind
  from
    gha_issues
  where
    closed_at >= '{{from}}'
    and closed_at < '{{to}}'
  ) sel2
where
  sel1.id = sel2.id
  and sel1.sig is not null
  and sel2.kind is not null
  and sel1.sig in (select sig_mentions_labels_name_with_all from tsig_mentions_labels_with_all)
  and sel2.kind in (select sigm_lbl_kind_name_with_all from tsigm_lbl_kinds_with_all)
group by
  sig_kind
order by
  cnt desc,
  sig_kind asc;
