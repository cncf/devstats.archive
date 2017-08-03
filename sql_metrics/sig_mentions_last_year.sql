select 
  substring(sig from 13) as sig, 
  count(*) as count_last_year
from 
  (
    select 
      substring(
        body from '(@kubernetes/sig-[\w-]+)(-bugs|-feature-request|-pr-review|-api-review|-misc|-proposal|-design-proposal|-test-failure)s?\s+'
      ) as sig 
    from 
      gha_view_last_year_texts
  ) sel 
where
  sel.sig is not null
group by 
  sel.sig
order by
  count_last_year desc,
  sel.sig asc
