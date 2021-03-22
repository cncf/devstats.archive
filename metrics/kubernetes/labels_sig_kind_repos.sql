select
  concat('sigm_lskr,', sel1.sig, '-', sel2.kind, '-', sel2.repo) as sig_kind_repo,
  round(count(distinct sel1.issue_id) / {{n}}, 2) as cnt
from (
  select sub.issue_id,
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
    select distinct issue_id,
      lower(substring(dup_label_name from '(?i)sig/(.*)')) as sig
    from
      gha_issues_labels
    where
      dup_created_at >= '{{from}}'
      and dup_created_at < '{{to}}'
  ) sub
  where
    sub.sig not in (
      'apimachinery', 'api-machiner', 'cloude-provider', 'nework',
      'scalability-proprosals', 'storge', 'ui-preview-reviewes',
      'cluster-fifecycle', 'rktnetes'
    )
    and sub.sig not like '%use-only-as-a-last-resort'
  union select id as issue_id,
    'All' as sig
  from
    gha_issues
  where
    created_at >= '{{from}}'
    and created_at < '{{to}}'
  ) sel1, (
  select distinct issue_id,
    dup_repo_name as repo,
    lower(substring(dup_label_name from '(?i)kind/(.*)')) as kind
  from
    gha_issues_labels
  where
    dup_created_at >= '{{from}}'
    and dup_created_at < '{{to}}'
  union select id as issue_id,
    dup_repo_name as repo,
    'All' as kind
  from
    gha_issues
  where
    created_at >= '{{from}}'
    and created_at < '{{to}}'
  ) sel2
where
  sel1.issue_id = sel2.issue_id
  and sel1.sig is not null
  and sel2.kind is not null
  and sel1.sig in (select sig_mentions_labels_name_with_all from tsig_mentions_labels_with_all)
  and sel2.kind in (select sigm_lbl_kind_name_with_all from tsigm_lbl_kinds_with_all)
  and sel2.repo in (select repo_name from trepos)
group by
  sig_kind_repo
order by
  cnt desc,
  sig_kind_repo asc;
