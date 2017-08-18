select 
  substring(sig from 13) as sig, 
  count(*) as count_last_month
from 
  (
    select 
      preg_capture(
        '{(@kubernetes/sig-[\\w-]+)(-bugs|-feature-request|-pr-review|-api-review|-misc|-proposal|-design-proposal|-test-failure)s?\\s+}i',
        body,
        1
      ) as sig
    from 
      gha_texts
    where
      created_at >= now() - interval 1 month
  ) sel 
where
  sel.sig is not null
group by 
  sel.sig
order by
  count_last_month desc,
  sel.sig asc
