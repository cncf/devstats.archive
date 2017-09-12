select
  substring(sig from 13) as sig,
  count(*) as count_value
from
  (
    select lower(coalesce(
        substring(
          body from '(?i)(?:^|\s)+(@kubernetes/sig-[\w\d-]+)(?:-bug|-feature-request|-pr-review|-api-review|-misc|-proposal|-design-proposal|-test-failure)s?(?:$|[^\w\d-]+)'
        ),
        substring(
          body from '(?i)(?:^|\s)+(@kubernetes/sig-[\w\d-]*[\w\d]+)(?:$|[^\w\d-]+)'
        )
      )) as sig
    from
      gha_texts
    where
      created_at >= '{{from}}'
      and created_at < '{{to}}'
  ) sel
where
  sel.sig is not null
group by
  sel.sig
order by
  count_value desc,
  sel.sig asc;
