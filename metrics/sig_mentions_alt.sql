select
  concat(substring(sig from 13), case when substring(grp from 1 for 1) = '-' then grp else '-all' end) as sig,
  count(*) as count_value
from
  (
    select coalesce(
        substring(
          body from '(?:^|\s)+(@kubernetes/sig-[\w\d-]+)(?:-bug|-feature-request|-pr-review|-api-review|-misc|-proposal|-design-proposal|-test-failure)s?(?:$|[^\w\d-]+)'
        ),
        substring(
          body from '(?:^|\s)+(@kubernetes/sig-[\w\d-]*[\w\d]+)(?:$|[^\w\d-]+)'
        )
      ) as sig,
    coalesce(
        substring(
          body from '(?:^|\s)+(?:@kubernetes/sig-[\w\d-]+)(-bug|-feature-request|-pr-review|-api-review|-misc|-proposal|-design-proposal|-test-failure)s?(?:$|[^\w\d-]+)'
        ),
        substring(
          body from '(?:^|\s)+(?:@kubernetes/sig-[\w\d-]*[\w\d]+)(?:$|[^\w\d-]+)'
        )
      ) as grp
    from
      gha_texts
    where
      created_at >= '{{from}}'
      and created_at < '{{to}}'
  ) sel
where
  sel.sig is not null
  and sel.grp is not null
group by
  sel.sig,
  sel.grp
order by
  count_value desc,
  sel.sig asc,
  sel.grp asc;
