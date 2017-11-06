select
  -- string_agg(sub.sig, ',')
  sub.sig
from (
  select sel.sig as sig,
  count(distinct issue_id) as cnt
  from (
    select distinct issue_id,
      lower(substring(dup_label_name from '(?i)sig/(.*)')) as sig
    from
      gha_issues_labels
    ) sel
  where
    sel.sig is not null
  group by
    sig
  order by
    cnt desc,
    sig asc
) sub
limit {{lim}}
;
