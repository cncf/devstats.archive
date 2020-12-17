create temp table dtto{{rnd}} as select case '{{to}}'::timestamp > now() when true then now() else '{{to}}'::timestamp end as dtto;
create temp table issues{{rnd}} as
  select distinct sub.issue_id,
    sub.user_id,
    sub.created_at,
    sub.event_id
  from (
    select distinct
      id as issue_id,
      last_value(event_id) over issues_ordered_by_update as event_id,
      first_value(user_id) over issues_ordered_by_update as user_id,
      first_value(created_at) over issues_ordered_by_update as created_at,
      last_value(closed_at) over issues_ordered_by_update as closed_at
    from
      gha_issues
    where
      created_at >= '{{to}}'::timestamp - '1 year'::interval
      and created_at < '{{to}}'
      and updated_at < '{{to}}'
      and is_pull_request = false
      and (lower(dup_user_login) {{exclude_bots}})
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
      sub.closed_at is null;
create index on issues{{rnd}}(issue_id);
create index on issues{{rnd}}(user_id);
create index on issues{{rnd}}(event_id);
create temp table issues_sigs{{rnd}} as
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
      select i.issue_id,
        i.event_id,
        lower(substring(il.dup_label_name from '(?i)sig/(.*)')) as sig
      from
        gha_issues_labels il,
        issues{{rnd}} i
      where
        il.issue_id = i.issue_id
        and il.event_id = i.event_id
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
  ) sub2;
create index on issues_sigs{{rnd}}(issue_id);
create temp table issues_act{{rnd}} as
  select i.issue_id,
    extract(epoch from i2.updated_at - i.created_at) as diff
  from
    issues{{rnd}} i,
    gha_issues i2
  where
    i.issue_id = i2.id
    and (lower(i2.dup_actor_login) {{exclude_bots}})
    and i2.updated_at < '{{to}}'
    and i2.event_id in (
      select event_id
      from
        gha_issues sub
      where
        sub.dup_actor_id != i.user_id
        and sub.id = i.issue_id
        and i2.updated_at < '{{to}}'
        and sub.updated_at > i.created_at + '30 seconds'::interval
        and sub.dup_type like '%Event'
      order by
        sub.updated_at asc
      limit 1
    );
create index on issues_act{{rnd}}(issue_id);
create temp table act{{rnd}} as
  select i.issue_id,
    coalesce(ia.diff, extract(epoch from d.dtto - i.created_at)) as inactive_for
  from
    dtto{{rnd}} d,
    issues{{rnd}} i
  left join
    issues_act{{rnd}} ia
  on
    i.issue_id = ia.issue_id;
create index on act{{rnd}}(issue_id);
select
  'inactive_issues_by_sig;' || sub.sig || ';w2,d30,d90' as metric,
  count(distinct sub.issue_id) filter(where sub.inactive_for > 1209600) as inactive_14,
  count(distinct sub.issue_id) filter(where sub.inactive_for > 2592000) as inactive_30,
  count(distinct sub.issue_id) filter(where sub.inactive_for > 7776000) as inactive_90
from
  (
  select s.sig,
    s.issue_id,
    a.inactive_for
  from
    issues_sigs{{rnd}} s,
    act{{rnd}} a
  where
    s.issue_id = a.issue_id
  ) sub
group by
  sub.sig
;
