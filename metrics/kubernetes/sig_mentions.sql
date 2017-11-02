select
  'sig_mentions_texts,' || substring(sig from 17) as sig,
  round(count(distinct eid) / {{n}}, 2) as count_value
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
