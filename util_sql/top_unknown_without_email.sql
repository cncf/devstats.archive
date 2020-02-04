with topu as (
  select e.actor_id,
    e.dup_actor_login as login
  from
    gha_events e
  left join
    gha_actors_affiliations aa
  on
    e.actor_id = aa.actor_id
  where
    e.type in (
      'CommitCommentEvent', 'IssueCommentEvent', 'IssuesEvent',
      'PullRequestEvent', 'PullRequestReviewCommentEvent', 'PushEvent'
    )
    and lower(e.dup_actor_login) not like all(array[
        'k8s-reviewable', 'codecov-io', 'grpc-jenkins', 'grpc-testing', 'k8s-teamcity-mesosphere',
        'angular-builds', 'devstats-sync', 'googlebot', 'hibernate-ci', 'coveralls', 'rktbot',
        'coreosbot', 'web-flow', 'prometheus-roobot', 'cncf-bot', 'kernelprbot', 'istio-testing',
        'spinnakerbot', 'pikbot', 'spinnaker-release', 'docker-jenkins', 'jenkins-x-bot',
        'golangcibot', 'opencontrail-ci-admin', 'titanium-octobot', 'asfgit', 'appveyorbot',
        'cadvisorjenkinsbot', 'gitcoinbot', 'katacontainersbot', 'prombot', 'prowbot', 'travis%bot',
        'k8s-%', '%-bot', '%-robot', 'bot-%', 'robot-%', '%[bot]%', '%[robot]%', '%-jenkins',
        '%-ci%bot', '%-testing', 'codecov-%', '%clabot%', '%cla-bot%', '%-gerrit', '%-bot-%', 
        '%envoy-filter-example%', 'strimzi-ci'
    ])
    and aa.actor_id is null
), others as (
  select distinct t.actor_id,
    a.id as other_actor_id,
    t.login
  from
    topu t,
    gha_actors a,
    gha_actors_affiliations aa
  where
    t.login = a.login
    and t.actor_id != a.id
    and a.id = aa.actor_id
), top as (
  select distinct t.actor_id,
    t.login
  from
    topu t
  left join
    others o
  on
    t.actor_id = o.actor_id
  where
    o.actor_id is null
)
select
  e.dup_actor_login as actor,
  count(distinct e.id) as cnt
from
  top t,
  gha_events e
left join
  gha_actors_emails ae
on
  e.actor_id = ae.actor_id
where
  t.actor_id = e.actor_id
  and e.type in (
      'CommitCommentEvent', 'IssueCommentEvent', 'IssuesEvent',
      'PullRequestEvent', 'PullRequestReviewCommentEvent', 'PushEvent'
    )
  and (ae.email is null or ae.email like '%users.noreply.github.com')
group by
  actor
order by
  cnt desc
limit
  20
;
-- select * from others;
-- select * from top;
