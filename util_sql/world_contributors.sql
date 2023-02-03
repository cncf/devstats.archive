select
  now() as "time",
  round(sqrt(count(distinct sub.login)::numeric), 0) as "value",
  coalesce(sub.country_id, '') as "name"
from (
  select
    a.login,
    e.id as event_id,
    coalesce(a.country_id, '') as country_id
  from
    gha_actors a,
    gha_events e,
    gha_repos r
  where
    e.repo_id = r.id
    and e.dup_repo_name = r.name
    and r.repo_group in ('Kubernetes')
    and e.dup_actor_login = a.login
    and e.type in ('IssuesEvent', 'PullRequestEvent', 'PushEvent', 'PullRequestReviewCommentEvent', 'IssueCommentEvent', 'CommitCommentEvent')
    and e.created_at BETWEEN '2011-12-31T23:00:00Z' AND '2023-02-03T05:47:12.199Z'
    and (e.dup_actor_login in (null) or 'null' = 'null')
    and lower(a.login) not like all(array['devstats-sync', 'googlebot', 'coveralls', 'rktbot', 'coreosbot', 'web-flow', 'prometheus-roobot', 'cncf-bot', 'kernelprbot', 'istio-testing', 'spinnakerbot', 'pikbot', 'spinnaker-release', 'docker-jenkins', 'golangcibot', 'opencontrail-ci-admin', 'k8s-%', '%-bot', '%-robot', 'bot-%', 'robot-%', '%[bot]%', '%-jenkins', '%-ci%bot', '%-testing', 'codecov-%', '%clabot%', '%cla-bot%', '%-gerrit', '%-bot-%'])
  union select
    a.login,
    c.event_id,
    coalesce(a.country_id, '') as country_id
  from
    gha_actors a,
    gha_commits c,
    gha_repos r
  where
    c.dup_repo_id = r.id
    and c.dup_repo_name = r.name
    and r.repo_group in ('Kubernetes')
    and c.dup_author_login = a.login
    and c.dup_created_at BETWEEN '2011-12-31T23:00:00Z' AND '2023-02-03T05:47:12.199Z'
    and (c.dup_author_login in (null) or 'null' = 'null')
    and lower(a.login) not like all(array['devstats-sync', 'googlebot', 'coveralls', 'rktbot', 'coreosbot', 'web-flow', 'prometheus-roobot', 'cncf-bot', 'kernelprbot', 'istio-testing', 'spinnakerbot', 'pikbot', 'spinnaker-release', 'docker-jenkins', 'golangcibot', 'opencontrail-ci-admin', 'k8s-%', '%-bot', '%-robot', 'bot-%', 'robot-%', '%[bot]%', '%-jenkins', '%-ci%bot', '%-testing', 'codecov-%', '%clabot%', '%cla-bot%', '%-gerrit', '%-bot-%'])
  union select
    a.login,
    c.event_id,
    coalesce(a.country_id, '') as country_id
  from
    gha_actors a,
    gha_commits c,
    gha_repos r
  where
    c.dup_repo_id = r.id
    and c.dup_repo_name = r.name
    and r.repo_group in ('Kubernetes')
    and c.dup_committer_login = a.login
    and c.dup_created_at BETWEEN '2011-12-31T23:00:00Z' AND '2023-02-03T05:47:12.199Z'
    and (c.dup_committer_login in (null) or 'null' = 'null')
    and lower(a.login) not like all(array['devstats-sync', 'googlebot', 'coveralls', 'rktbot', 'coreosbot', 'web-flow', 'prometheus-roobot', 'cncf-bot', 'kernelprbot', 'istio-testing', 'spinnakerbot', 'pikbot', 'spinnaker-release', 'docker-jenkins', 'golangcibot', 'opencontrail-ci-admin', 'k8s-%', '%-bot', '%-robot', 'bot-%', 'robot-%', '%[bot]%', '%-jenkins', '%-ci%bot', '%-testing', 'codecov-%', '%clabot%', '%cla-bot%', '%-gerrit', '%-bot-%'])
) sub
where
  sub.country_id != ''
group by
  sub.country_id
;
