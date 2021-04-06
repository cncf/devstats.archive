select
  -- string_agg(sub.actor, ',')
  sub.actor
from (
  select distinct sub2.actor
  from (
    select a.login as actor
    from
      gha_events e,
      gha_actors a
    where
      (e.actor_id = a.id or e.dup_actor_login = a.login)
      and e.type in (
        'PullRequestReviewCommentEvent', 'PushEvent', 'PullRequestEvent',
        'IssuesEvent', 'IssueCommentEvent', 'CommitCommentEvent'
      )
      and lower(a.login) not like all(array['openssl-machine', 'sizebot', 'dependabot', 'cncf-ci', 'poiana', 'svcbot-qecnsdp', 'nsmbot', 'ti-srebot', 'cf-buildpacks-eng', 'bosh-ci-push-pull', 'gprasath', 'zephyr-github', 'zephyrbot', 'strimzi-ci', 'athenabot', 'k8s-reviewable', 'codecov-io', 'grpc-testing', 'k8s-teamcity-mesosphere', 'angular-builds', 'devstats-sync', 'googlebot', 'hibernate-ci', 'coveralls', 'rktbot', 'coreosbot', 'web-flow', 'prometheus-roobot', 'cncf-bot', 'kernelprbot', 'istio-testing', 'spinnakerbot', 'pikbot', 'spinnaker-release', 'golangcibot', 'opencontrail-ci-admin', 'titanium-octobot', 'asfgit', 'appveyorbot', 'cadvisorjenkinsbot', 'gitcoinbot', 'katacontainersbot', 'prombot', 'prowbot', 'travis%bot', 'k8s-%', '%-bot', '%-robot', 'bot-%', 'robot-%', '%[bot]%', '%[robot]%', '%-jenkins', 'jenkins-%', '%-ci%bot', '%-testing', 'codecov-%', '%clabot%', '%cla-bot%', '%-gerrit', '%-bot-%', '%envoy-filter-example%', '%cibot', '%-ci'])
    union select a.login as actor
    from
      gha_commits c,
      gha_actors a
    where
      (c.committer_id = a.id or c.dup_committer_login = a.login)
      and lower(a.login) not like all(array['openssl-machine', 'sizebot', 'dependabot', 'cncf-ci', 'poiana', 'svcbot-qecnsdp', 'nsmbot', 'ti-srebot', 'cf-buildpacks-eng', 'bosh-ci-push-pull', 'gprasath', 'zephyr-github', 'zephyrbot', 'strimzi-ci', 'athenabot', 'k8s-reviewable', 'codecov-io', 'grpc-testing', 'k8s-teamcity-mesosphere', 'angular-builds', 'devstats-sync', 'googlebot', 'hibernate-ci', 'coveralls', 'rktbot', 'coreosbot', 'web-flow', 'prometheus-roobot', 'cncf-bot', 'kernelprbot', 'istio-testing', 'spinnakerbot', 'pikbot', 'spinnaker-release', 'golangcibot', 'opencontrail-ci-admin', 'titanium-octobot', 'asfgit', 'appveyorbot', 'cadvisorjenkinsbot', 'gitcoinbot', 'katacontainersbot', 'prombot', 'prowbot', 'travis%bot', 'k8s-%', '%-bot', '%-robot', 'bot-%', 'robot-%', '%[bot]%', '%[robot]%', '%-jenkins', 'jenkins-%', '%-ci%bot', '%-testing', 'codecov-%', '%clabot%', '%cla-bot%', '%-gerrit', '%-bot-%', '%envoy-filter-example%', '%cibot', '%-ci'])
    union select a.login as actor
    from
      gha_commits c,
      gha_actors a
    where
      (c.author_id = a.id or c.dup_author_login = a.login)
      and lower(a.login) not like all(array['openssl-machine', 'sizebot', 'dependabot', 'cncf-ci', 'poiana', 'svcbot-qecnsdp', 'nsmbot', 'ti-srebot', 'cf-buildpacks-eng', 'bosh-ci-push-pull', 'gprasath', 'zephyr-github', 'zephyrbot', 'strimzi-ci', 'athenabot', 'k8s-reviewable', 'codecov-io', 'grpc-testing', 'k8s-teamcity-mesosphere', 'angular-builds', 'devstats-sync', 'googlebot', 'hibernate-ci', 'coveralls', 'rktbot', 'coreosbot', 'web-flow', 'prometheus-roobot', 'cncf-bot', 'kernelprbot', 'istio-testing', 'spinnakerbot', 'pikbot', 'spinnaker-release', 'golangcibot', 'opencontrail-ci-admin', 'titanium-octobot', 'asfgit', 'appveyorbot', 'cadvisorjenkinsbot', 'gitcoinbot', 'katacontainersbot', 'prombot', 'prowbot', 'travis%bot', 'k8s-%', '%-bot', '%-robot', 'bot-%', 'robot-%', '%[bot]%', '%[robot]%', '%-jenkins', 'jenkins-%', '%-ci%bot', '%-testing', 'codecov-%', '%clabot%', '%cla-bot%', '%-gerrit', '%-bot-%', '%envoy-filter-example%', '%cibot', '%-ci'])
    ) sub2
  order by
    sub2.actor asc
  ) sub
;
