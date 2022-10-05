delete from gha_bot_logins;
insert into gha_bot_logins
  select
    l.l
  from
    unnest(array['claassistant', 'containersshbuilder', 'wasmcloud-automation', 'fossabot', 'facebook-github-whois-bot-0', 'knative-automation', 'covbot', 'cdk8s-automation', 'github-action-benchmark', 'goreleaserbot', 'imgbotapp', 'backstage-service', 'openssl-machine', 'sizebot', 'dependabot', 'cncf-ci', 'poiana', 'svcbot-qecnsdp', 'nsmbot', 'ti-srebot', 'cf-buildpacks-eng', 'bosh-ci-push-pull', 'gprasath', 'zephyr-github', 'zephyrbot', 'strimzi-ci', 'athenabot', 'k8s-reviewable', 'codecov-io', 'grpc-testing', 'k8s-teamcity-mesosphere', 'angular-builds', 'devstats-sync', 'googlebot', 'hibernate-ci', 'coveralls', 'rktbot', 'coreosbot', 'web-flow', 'prometheus-roobot', 'cncf-bot', 'kernelprbot', 'istio-testing', 'spinnakerbot', 'pikbot', 'spinnaker-release', 'golangcibot', 'opencontrail-ci-admin', 'titanium-octobot', 'asfgit', 'appveyorbot', 'cadvisorjenkinsbot', 'gitcoinbot', 'katacontainersbot', 'prombot', 'prowbot', 'travis%bot', 'k8s-%', '%-bot', '%-robot', 'bot-%', 'robot-%', '%[bot]%', '%[robot]%', '%-jenkins', 'jenkins-%', '%-ci%bot', '%-testing', 'codecov-%', '%clabot%', '%cla-bot%', '%-gerrit', '%-bot-%', '%envoy-filter-example%', '%cibot', '%-ci'])
    as l(l)
;
