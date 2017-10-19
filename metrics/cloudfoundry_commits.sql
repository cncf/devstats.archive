select
  count(distinct sha) as number_of_commits
from
  gha_commits
where
  author_name not in
(
'CI Pool Resource',
'CF Buildpacks Team CI Server',
'CAPI CI',
'CF MEGA BOT',
'I am Groot CI',
'CI (automated)',
'Loggregator CI',
'CI (Automated)',
'CI Bot',
'cf-infra-bot',
'CI',
'cf-loggregator',
'bot',
'CF INFRASTRUCTURE BOT',
'CF Garden',
'Container Networking Bot',
'Routing CI (Automated)',
'CF-Identity',
'BOSH CI',
'CF Loggregator CI Pipeline',
'CF Infrastructure',
'CI Submodule AutoUpdate',
'routing-ci',
'Concourse Bot',
'CF Toronto CI Bot',
'Concourse CI',
'Pivotal Concourse Bot',
'RUNTIME OG CI',
'CF CredHub CI Pipeline',
'CF CI Pipeline',
'CF Identity',
'PCF Security Enablement CI',
'CI BOT',
'Cloudops CI',
'hcf-bot',
'Cloud Foundry Buildpacks Team Robot',
'CF CORE SERVICES BOT',
'PCF Security Enablement',
'fizzy bot',
'Appdog CI Bot',
'CF Tribe',
'Greenhouse CI'
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
  and dup_created_at >= '{{from}}'
  and dup_created_at < '{{to}}'
;
