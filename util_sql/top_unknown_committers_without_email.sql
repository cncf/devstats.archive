with topu as (
  select distinct sub.actor_id,
    sub.login
  from (
    select c.dup_actor_id as actor_id,
      c.dup_actor_login as login
    from
      gha_commits c
    left join
      gha_actors_affiliations aa
    on
      c.dup_actor_id = aa.actor_id
    where
      lower(c.dup_actor_login) not like all(array['goreleaserbot', 'imgbotapp', 'backstage-service', 'openssl-machine', 'sizebot', 'dependabot', 'cncf-ci', 'poiana', 'svcbot-qecnsdp', 'nsmbot', 'ti-srebot', 'cf-buildpacks-eng', 'bosh-ci-push-pull', 'gprasath', 'zephyr-github', 'zephyrbot', 'strimzi-ci', 'athenabot', 'k8s-reviewable', 'codecov-io', 'grpc-testing', 'k8s-teamcity-mesosphere', 'angular-builds', 'devstats-sync', 'googlebot', 'hibernate-ci', 'coveralls', 'rktbot', 'coreosbot', 'web-flow', 'prometheus-roobot', 'cncf-bot', 'kernelprbot', 'istio-testing', 'spinnakerbot', 'pikbot', 'spinnaker-release', 'golangcibot', 'opencontrail-ci-admin', 'titanium-octobot', 'asfgit', 'appveyorbot', 'cadvisorjenkinsbot', 'gitcoinbot', 'katacontainersbot', 'prombot', 'prowbot', 'travis%bot', 'k8s-%', '%-bot', '%-robot', 'bot-%', 'robot-%', '%[bot]%', '%[robot]%', '%-jenkins', 'jenkins-%', '%-ci%bot', '%-testing', 'codecov-%', '%clabot%', '%cla-bot%', '%-gerrit', '%-bot-%', '%envoy-filter-example%', '%cibot', '%-ci'])
      and aa.actor_id is null
    union select c.author_id as actor_id,
      c.dup_author_login as login
    from
      gha_commits c
    left join
      gha_actors_affiliations aa
    on
      c.author_id = aa.actor_id
    where
      lower(c.dup_author_login) not like all(array['goreleaserbot', 'imgbotapp', 'backstage-service', 'openssl-machine', 'sizebot', 'dependabot', 'cncf-ci', 'poiana', 'svcbot-qecnsdp', 'nsmbot', 'ti-srebot', 'cf-buildpacks-eng', 'bosh-ci-push-pull', 'gprasath', 'zephyr-github', 'zephyrbot', 'strimzi-ci', 'athenabot', 'k8s-reviewable', 'codecov-io', 'grpc-testing', 'k8s-teamcity-mesosphere', 'angular-builds', 'devstats-sync', 'googlebot', 'hibernate-ci', 'coveralls', 'rktbot', 'coreosbot', 'web-flow', 'prometheus-roobot', 'cncf-bot', 'kernelprbot', 'istio-testing', 'spinnakerbot', 'pikbot', 'spinnaker-release', 'golangcibot', 'opencontrail-ci-admin', 'titanium-octobot', 'asfgit', 'appveyorbot', 'cadvisorjenkinsbot', 'gitcoinbot', 'katacontainersbot', 'prombot', 'prowbot', 'travis%bot', 'k8s-%', '%-bot', '%-robot', 'bot-%', 'robot-%', '%[bot]%', '%[robot]%', '%-jenkins', 'jenkins-%', '%-ci%bot', '%-testing', 'codecov-%', '%clabot%', '%cla-bot%', '%-gerrit', '%-bot-%', '%envoy-filter-example%', '%cibot', '%-ci'])
      and aa.actor_id is null
    union select c.committer_id as actor_id,
      c.dup_committer_login as login
    from
      gha_commits c
    left join
      gha_actors_affiliations aa
    on
      c.committer_id = aa.actor_id
    where
      lower(c.dup_committer_login) not like all(array['goreleaserbot', 'imgbotapp', 'backstage-service', 'openssl-machine', 'sizebot', 'dependabot', 'cncf-ci', 'poiana', 'svcbot-qecnsdp', 'nsmbot', 'ti-srebot', 'cf-buildpacks-eng', 'bosh-ci-push-pull', 'gprasath', 'zephyr-github', 'zephyrbot', 'strimzi-ci', 'athenabot', 'k8s-reviewable', 'codecov-io', 'grpc-testing', 'k8s-teamcity-mesosphere', 'angular-builds', 'devstats-sync', 'googlebot', 'hibernate-ci', 'coveralls', 'rktbot', 'coreosbot', 'web-flow', 'prometheus-roobot', 'cncf-bot', 'kernelprbot', 'istio-testing', 'spinnakerbot', 'pikbot', 'spinnaker-release', 'golangcibot', 'opencontrail-ci-admin', 'titanium-octobot', 'asfgit', 'appveyorbot', 'cadvisorjenkinsbot', 'gitcoinbot', 'katacontainersbot', 'prombot', 'prowbot', 'travis%bot', 'k8s-%', '%-bot', '%-robot', 'bot-%', 'robot-%', '%[bot]%', '%[robot]%', '%-jenkins', 'jenkins-%', '%-ci%bot', '%-testing', 'codecov-%', '%clabot%', '%cla-bot%', '%-gerrit', '%-bot-%', '%envoy-filter-example%', '%cibot', '%-ci'])
      and aa.actor_id is null
  ) sub
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
  sub.actor,
  count(distinct sha) as cnt
from (
  select
    c.dup_actor_login as actor,
    c.sha
  from
    top t,
    gha_commits c
  left join
    gha_actors_emails ae
  on
    c.dup_actor_id = ae.actor_id
  where
    t.actor_id = c.dup_actor_id
    and (ae.email is null or ae.email like '%users.noreply.github.com')
  union select
    c.dup_author_login as actor,
    c.sha
  from
    top t,
    gha_commits c
  left join
    gha_actors_emails ae
  on
    c.author_id = ae.actor_id
  where
    t.actor_id = c.author_id
    and (ae.email is null or ae.email like '%users.noreply.github.com')
  union select
    c.dup_committer_login as actor,
    c.sha
  from
    top t,
    gha_commits c
  left join
    gha_actors_emails ae
  on
    c.committer_id = ae.actor_id
  where
    t.actor_id = c.committer_id
    and (ae.email is null or ae.email like '%users.noreply.github.com')
  ) sub
group by
  actor
order by
  cnt desc
limit
  20
;
