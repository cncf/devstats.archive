select
  -- string_agg(sub.actor, ',')
  sub.actor
from (
  select distinct a.login as actor
  from
    gha_events e,
    gha_actors a
  where
    (e.actor_id = a.id or e.dup_actor_login = a.login)
    and e.type in (
      'PullRequestReviewCommentEvent', 'PushEvent', 'PullRequestEvent',
      'IssuesEvent', 'IssueCommentEvent', 'CommitCommentEvent'
    )
    and lower(a.login) not like all(array['angular-builds', 'devstats-sync', 'googlebot', 'coveralls', 'rktbot', 'coreosbot', 'web-flow', 'prometheus-roobot', 'cncf-bot', 'kernelprbot', 'istio-testing', 'spinnakerbot', 'pikbot', 'spinnaker-release', 'docker-jenkins', 'jenkins-x-bot', 'golangcibot', 'opencontrail-ci-admin', 'titanium-octobot', 'asfgit', 'travis%bot', 'k8s-%', '%-bot', '%-robot', 'bot-%', 'robot-%', '%[bot]%', '%-jenkins', '%-ci%bot', '%-testing', 'codecov-%', '%clabot%', '%cla-bot%', '%-gerrit', '%-bot-%', '%envoy-filter-example%'])
  order by
    actor asc
  ) sub
;
