create temp table issues{{rnd}} as
  select sub.issue_id,
    sub.event_id
  from (
    select distinct
      id as issue_id,
      last_value(event_id) over issues_ordered_by_update as event_id,
      last_value(closed_at) over issues_ordered_by_update as closed_at
    from
      gha_issues
    where
      created_at >= {{to}}::timestamp - '1 year'::interval
      and created_at < {{to}}
      and updated_at < {{to}}
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
    sub.closed_at is null;
create index on issues{{rnd}}(issue_id);
create temp table prs{{rnd}} as
  select i.issue_id,
    i.event_id
  from (
    select distinct id as pr_id,
      last_value(closed_at) over prs_ordered_by_update as closed_at,
      last_value(merged_at) over prs_ordered_by_update as merged_at
    from
      gha_pull_requests
    where
      created_at >= {{to}}::timestamp - '1 year'::interval
      and created_at < {{to}}
      and updated_at < {{to}}
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
    issues{{rnd}} i,
    gha_issues_pull_requests ipr
  where
    ipr.issue_id = i.issue_id
    and ipr.pull_request_id = pr.pr_id
    and pr.closed_at is null
    and pr.merged_at is null;
create index on prs{{rnd}}(issue_id);
create index on prs{{rnd}}(event_id);
create temp table pr_sizes{{rnd}} as
  select sub.issue_id,
    sub.size
  from (
    select pr.issue_id,
      lower(substring(il.dup_label_name from '(?i)size/(.*)')) as size
    from
      gha_issues_labels il,
      prs{{rnd}} pr
    where
      il.issue_id = pr.issue_id
      and il.event_id = pr.event_id
    ) sub
  where
    sub.size is not null;
create index on pr_sizes{{rnd}}(issue_id);
create temp table pr_sigs{{rnd}} as
  select sub2.issue_id,
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
      sub.sig
    from (
      select pr.issue_id,
        lower(substring(il.dup_label_name from '(?i)sig/(.*)')) as sig
      from
        gha_issues_labels il,
        prs{{rnd}} pr
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
  ) sub2;
create index on pr_sigs{{rnd}}(issue_id);
create temp table reviewers_text{{rnd}} as
  select t.event_id,
    pl.issue_id
  from
    gha_texts t,
    gha_payloads pl
  where
    {{period:t.created_at}}
    and t.event_id = pl.event_id
    and substring(t.body from '(?i)(?:^|\n|\r)\s*/(?:lgtm|approve)\s*(?:\n|\r|$)') is not null
    and (lower(t.actor_login) {{exclude_bots}});
create temp table issue_events{{rnd}} as
  select distinct sub.event_id,
    sub.issue_id
  from (
    select min(event_id) as event_id,
      issue_id
    from
      gha_issues_labels
    where
      {{period:dup_created_at}}
      and dup_label_name in ('lgtm', 'approved')
      and (lower(dup_actor_login) {{exclude_bots}})
    group by
      issue_id
    union select event_id, issue_id from reviewers_text{{rnd}}
    ) sub;
create index on issue_events{{rnd}}(issue_id);
create index on issue_events{{rnd}}(event_id);
create temp table issue_sig_labels{{rnd}} as
  select distinct issue_id,
    lower(substring(dup_label_name from '(?i)sig/(.*)')) as sig
  from
    gha_issues_labels
  where
    {{period:dup_created_at}};
create index on issue_sig_labels{{rnd}}(issue_id);
create temp table sig_reviewers{{rnd}} as
  select sub2.sig,
    count(distinct sub2.dup_actor_login) as rev
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
      e.dup_actor_login
    from
      issue_sig_labels{{rnd}} sub,
      issue_events{{rnd}} ie,
      gha_events e
    where
      sub.sig is not null
      and sub.sig not in (
        'apimachinery', 'api-machiner', 'cloude-provider', 'nework',
        'scalability-proprosals', 'storge', 'ui-preview-reviewes',
        'cluster-fifecycle', 'rktnetes'
      )
      and sub.sig not like '%use-only-as-a-last-resort'
      and ie.issue_id = sub.issue_id
      and ie.event_id = e.id
  ) sub2
  group by
    sub2.sig;
create index on sig_reviewers{{rnd}}(sig);
select
  'hpr_wl;sig:s,iss:f,abs:f,rev:f,rel:f;sigs' as metric,
  sub.sig,
  sub.iss,
  sub.abs,
  coalesce(sr.rev, 0) as rev,
  case coalesce(sr.rev, 0)
    when 0 then 0
    else sub.abs / sr.rev
  end as rel
from (
  select
    sig.sig as sig,
    count(distinct sig.issue_id) as iss,
    sum(
      case coalesce(siz.size, 'nil')
        when 'xs' then 0.25
        when 's' then 0.5
        when 'small' then 0.5
        when 'm' then 1.0
        when 'medium' then 1.0
        when 'nil' then 1.0
        when 'l' then 2.0
        when 'large' then 2.0
        when 'xl' then 4.0
        when 'xxl' then 8.0
        else 1.0
      end
    ) as abs
  from
    pr_sigs{{rnd}} sig
  left join
    pr_sizes{{rnd}} siz
  on
    sig.issue_id = siz.issue_id
  group by
    sig.sig
  ) sub
left join
  sig_reviewers{{rnd}} sr
on
  sub.sig = sr.sig
where
  sub.sig in (select sig_mentions_labels_name from tsig_mentions_labels)
order by
  rel desc,
  sub.sig asc
;
