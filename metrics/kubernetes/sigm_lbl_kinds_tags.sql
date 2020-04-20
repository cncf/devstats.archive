select
  -- string_agg(sub3.kind, ',')
  sub3.kind
from (
  select sub2.kind,
    count(distinct sub2.issue_id) as cnt
  from (
    select sub.kind,
      sub.issue_id
    from (
      select sel.kind,
        sel.issue_id
      from (
        select distinct issue_id,
          lower(substring(dup_label_name from '(?i)kind/(.*)')) as kind
        from
          gha_issues_labels
        where
          dup_created_at > now() - '2 years'::interval
        ) sel
      where
        sel.kind is not null
    ) sub
  ) sub2
  group by
    sub2.kind
  having
    count(distinct sub2.issue_id) > 30
) sub3
order by
  cnt desc,
  sub3.kind asc
limit {{lim}}
;
