with issues as (
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
      created_at < '{{to}}'
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
  select i.issue_id,
    i.event_id
  from (
    select distinct id as pr_id,
      last_value(closed_at) over prs_ordered_by_update as closed_at,
      last_value(merged_at) over prs_ordered_by_update as merged_at
    from
      gha_pull_requests
    where
      created_at < '{{to}}'
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
), pr_sizes as (
  select sub.issue_id,
    sub.size
  from (
    select pr.issue_id,
      lower(substring(il.dup_label_name from '(?i)size/(.*)')) as size
    from
      gha_issues_labels il,
      prs pr
    where
      il.issue_id = pr.issue_id
      and il.event_id = pr.event_id
    ) sub
  where
    sub.size is not null
), pr_sigs as (
  select sub.issue_id,
    sub.sig
  from (
    select pr.issue_id,
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
), reviewers_text as (
  select t.event_id,
    pl.issue_id
  from
    gha_texts t,
    gha_payloads pl
  where
    t.created_at < '{{to}}'
    and t.created_at >= '{{to}}'::date - '1 month'::interval
    and t.event_id = pl.event_id
    and substring(t.body from '(?i)(?:^|\n|\r)\s*/(?:lgtm|approve)\s*(?:\n|\r|$)') is not null
    and (lower(t.actor_login) {{exclude_bots}})
), issue_events as (
  select distinct sub.event_id,
    sub.issue_id
  from (
    select min(event_id) as event_id,
      issue_id
    from
      gha_issues_labels
    where
      dup_label_name in ('lgtm', 'approved')
      and dup_created_at < '{{to}}'
      and dup_created_at >= '{{to}}'::date - '1 month'::interval
      and (lower(dup_actor_login) {{exclude_bots}})
    group by
      issue_id
    union select event_id, issue_id from reviewers_text
    ) sub
), sig_reviewers as (
  select sub.sig,
    count(distinct e.dup_actor_login) as rev
  from (
    select distinct issue_id,
      lower(substring(dup_label_name from '(?i)sig/(.*)')) as sig
    from
      gha_issues_labels
    ) sub,
    issue_events ie,
    gha_events e
  where
    sub.sig is not null
    and ie.issue_id = sub.issue_id
    and ie.event_id = e.id
  group by
    sub.sig
)
select
  'sig_pr_wl;' || sub.sig || ';iss,abs,rev,rel',
  sub.iss,
  sub.abs,
  coalesce(sr.rev, 0) as rev,
  case coalesce(sr.rev, 0)
    when 0 then 0
    else sub.abs / sr.rev
  end as rel
from (
  select sig.sig,
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
    pr_sigs sig
  left join
    pr_sizes siz
  on
    sig.issue_id = siz.issue_id
  group by
    sig.sig
  ) sub
left join
  sig_reviewers sr
on
  sub.sig = sr.sig
order by
  rel desc,
  sub.sig asc
;
