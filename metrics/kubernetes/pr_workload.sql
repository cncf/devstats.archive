create temp table pr_sizes as
select
  sub.issue_id,
  sub.size
from (
  select distinct issue_id,
    lower(substring(dup_label_name from '(?i)size/(.*)')) as size
  from
    gha_issues_labels
  where
    {{period:dup_created_at}}
  ) sub
where
  sub.size is not null
;

create temp table pr_sigs as
select
  sub.issue_id,
  sub.sig
from (
  select distinct issue_id,
    lower(substring(dup_label_name from '(?i)sig/(.*)')) as sig
  from
    gha_issues_labels
  where
    {{period:dup_created_at}}
  ) sub
where
  sub.sig is not null
;

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
order by
  absolute_workload desc,
  sig asc
;

drop table pr_sizes;
drop table pr_sigs;
