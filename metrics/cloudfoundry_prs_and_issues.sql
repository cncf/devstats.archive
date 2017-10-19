select
  count(distinct id) as number_of_prs_and_issues
from
  gha_issues
where
  created_at >= '{{from}}'
  and created_at < '{{to}}'
  and dup_user_login not in
(
'cf-buildpacks-eng',
'cm-release-bot',
'capi-bot',
'runtime-ci',
'cf-infra-bot',
'routing-ci',
'pcf-core-services-writer',
'cf-loggregator-oauth-bot',
'cf-identity',
'hcf-bot',
'cfadmins-deploykey-user',
'cf-pub-tools',
'pcf-toronto-ci-bot',
'perm-ci-bot',
'backup-restore-team-bot',
'greenhouse-ci'
)
  and dup_actor_login not in
(
'cf-buildpacks-eng',
'cm-release-bot',
'capi-bot',
'runtime-ci',
'cf-infra-bot',
'routing-ci',
'pcf-core-services-writer',
'cf-loggregator-oauth-bot',
'cf-identity',
'hcf-bot',
'cfadmins-deploykey-user',
'cf-pub-tools',
'pcf-toronto-ci-bot',
'perm-ci-bot',
'backup-restore-team-bot',
'greenhouse-ci'
)
;
/*
select
  count(distinct id) as number_of_prs_and_issues
from
  gha_events
where
  created_at >= '{{from}}'
  and created_at < '{{to}}'
  and type in ('PullRequestEvent', 'IssuesEvent')
;*/
