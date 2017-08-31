select
  substring(sig from 13) as sig,
  count(*) as count_all_time
from
  (
    select coalesce(
        substring(
          body from '(?:^|\s)+(@kubernetes/sig-[\w\d-]+)(?:-bug|-feature-request|-pr-review|-api-review|-misc|-proposal|-design-proposal|-test-failure)s?(?:$|[^\w\d-]+)'
        ),
        substring(
          body from '(?:^|\s)+(@kubernetes/sig-[\w\d-]*[\w\d]+)(?:$|[^\w\d-]+)'
        )
      ) as sig
    from
      gha_texts
  ) sel
where
  sel.sig is not null
group by
  sel.sig
order by
  count_all_time desc,
  sel.sig asc
