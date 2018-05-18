select
  -- string_agg(sub.sig, ',')
  sub.sig
from (
  select substring(sig from 17) as sig,
    count(distinct eid) as count_value
  from
    (
      select event_id as eid,
        lower(coalesce(
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
        (lower(actor_login) {{exclude_bots}})
    ) sel
  where
    sel.sig is not null
  group by
    sel.sig
  order by
    count_value desc,
    sel.sig asc
) sub
limit {{lim}}
;
