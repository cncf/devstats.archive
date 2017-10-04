select sub.name from (
  select
    c.name as name,
    count(distinct e.id) as cnt
  from
    gha_companies c,
    gha_actors_affiliations aa,
    gha_events e
  where
    aa.company_name = c.name
    and e.actor_id = aa.actor_id
    and c.name in (
      'Google', 'Self', 'Red Hat', 'CoreOS', 'Apple',
      'Microsoft', 'Mesosphere', 'Caicloud', 'Mirantis', 'Huawei',
      'Weaveworks', 'Cockroach', 'Morea', 'VMware', 'Zalando',
      'Apprenda', 'Tigera', 'Dell', 'Heptio', 'Fujitsu',
      'HP', 'Samsung', 'Box', 'Bitnami', 'Hyper.sh',
      'Intel', 'IBM', 'Apache', 'CNCF', 'Codecentric AG',
      'EasyStack'
    )
  group by
    c.name
  order by
    cnt desc,
    name asc
) sub
;
