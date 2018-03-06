create temp table issues as
select sub.issue_id
from (
  select
    ipr.issue_id as issue_id,
    min(pr.created_at) as opened_at,
    max(pr.closed_at) as closed_at
  from
    gha_issues_pull_requests ipr,
    gha_pull_requests pr
  where
    ipr.pull_request_id = pr.id
    and pr.created_at < '{{to}}'
    and ipr.issue_id > 0
  group by
    ipr.issue_id
  ) sub
where
  sub.closed_at is null or sub.closed_at >= '{{to}}'
;

create temp table pr_sizes as
select
  sub.issue_id,
  sub.size
from (
  select distinct i.issue_id,
    lower(substring(il.dup_label_name from '(?i)size/(.*)')) as size
  from
    gha_issues_labels il,
    issues i
  where
    il.issue_id = i.issue_id
  ) sub
where
  sub.size is not null
;

create temp table pr_sigs as
select
  sub.issue_id,
  sub.sig
from (
  select distinct i.issue_id,
    lower(substring(il.dup_label_name from '(?i)sig/(.*)')) as sig
  from
    gha_issues_labels il,
    issues i
  where
    il.issue_id = i.issue_id
  ) sub
where
  sub.sig is not null
;

create temp table reviewers_text as
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
  and (t.actor_login {{exclude_bots}})
;

create temp table issue_events as
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
    and (dup_actor_login {{exclude_bots}})
  group by
    issue_id
  union select event_id, issue_id from reviewers_text
  ) sub
;

create temp table sig_reviewers as
select
  sub.sig,
  count(distinct e.dup_actor_login) as reviewers
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
;

select
  'sig_pr_workload;' || sub.sig || ';issues,absolute_workload,reviewers,relative_workload',
  sub.issues,
  sub.absolute_workload,
  coalesce(sr.reviewers, 0) as reviewers,
  case coalesce(sr.reviewers, 0)
    when 0 then 0
    else sub.absolute_workload / sr.reviewers
  end as relative_workload
from (
  select
    sig.sig,
    count(distinct sig.issue_id) as issues,
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
    ) as absolute_workload
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
  relative_workload desc,
  sub.sig asc
;

drop table sig_reviewers;
drop table issue_events;
drop table reviewers_text;
drop table pr_sigs;
drop table pr_sizes;
drop table issues;
