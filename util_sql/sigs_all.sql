select
  sub2.sig
from (
  select
    distinct substring(lower(substring(body from '(?i)(?:^|\s)+(@kubernetes/sig-[\w\d-]+)(?:-bug|-feature-request|-pr-reviews|-api-review|-misc|-proposal|-design-proposal|-test-failure|-owners)s?(?:$|[^\w\d-]+)')) from 17) as sig
  from
    gha_texts
  where
    created_at >= now() - '10 years'::interval
  union select
    distinct lower(substring(sub.dup_label_name from '(?i)sig/(.*)')) as sig
  from (
    select
      distinct dup_label_name
    from
      gha_issues_labels
    ) sub
  ) sub2
where
  sub2.sig is not null
order by
  sub2.sig
;
