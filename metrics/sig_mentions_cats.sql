select
  'cat,' || substring(sig from 2) as sig,
  count(*) as count_value
from
  (
    select lower(substring(
          body from '(?i)(?:^|\s)+(?:@kubernetes/sig-[\w\d-]+)(-bug|-feature-request|-pr-review|-api-review|-misc|-proposal|-design-proposal|-test-failure)s?(?:$|[^\w\d-]+)'
        )) as sig
    from
      gha_texts
    where
      created_at >= '{{from}}'
      and created_at < '{{to}}'
      and actor_login not in ('googlebot')
      and actor_login not like 'k8s-%'
      and actor_login not like '%-bot'
      and actor_login not like '%-robot'
  ) sel
where
  sel.sig is not null
group by
  sel.sig
order by
  count_value desc,
  sel.sig asc;
