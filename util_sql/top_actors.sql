select
  e.dup_actor_login,
  a.company_name,
  a.dt_from,
  a.dt_to,
  count(distinct e.id) as cnt
from
  gha_events e
left join
  gha_actors_affiliations a
on
  e.actor_id = a.actor_id
  and a.company_name != ''
where
  e.dup_actor_login not like all(array['zephyr-github', 'zephyrbot', 'strimzi-ci', 'athenabot', 'k8s-reviewable', 'codecov-io', 'grpc-testing', 'k8s-teamcity-mesosphere', 'angular-builds', 'devstats-sync', 'googlebot', 'hibernate-ci', 'coveralls', 'rktbot', 'coreosbot', 'web-flow', 'prometheus-roobot', 'cncf-bot', 'kernelprbot', 'istio-testing', 'spinnakerbot', 'pikbot', 'spinnaker-release', 'golangcibot', 'opencontrail-ci-admin', 'titanium-octobot', 'asfgit', 'appveyorbot', 'cadvisorjenkinsbot', 'gitcoinbot', 'katacontainersbot', 'prombot', 'prowbot', 'travis%bot', 'k8s-%', '%-bot', '%-robot', 'bot-%', 'robot-%', '%[bot]%', '%[robot]%', '%-jenkins', 'jenkins-%', '%-ci%bot', '%-testing', 'codecov-%', '%clabot%', '%cla-bot%', '%-gerrit', '%-bot-%', '%envoy-filter-example%'])
group by
  e.dup_actor_login,
  a.company_name,
  a.dt_from,
  a.dt_to
order by
  cnt desc
limit
  30
;
