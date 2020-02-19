-- Add repository groups
with repo_latest as (
  select sub.repo_id,
    sub.repo_name
  from (
    select repo_id,
      dup_repo_name as repo_name,
      row_number() over (partition by repo_id order by created_at desc, id desc) as row_num
    from
      gha_events
  ) sub
  where
    sub.row_num = 1
)
update
  gha_repos r
set
  alias = (
    select rl.repo_name
    from
      repo_latest rl
    where
      rl.repo_id = r.id
  )
where
  r.name like '%_/_%'
  and r.name not like '%/%/%'
;
update gha_repos set repo_group = alias;

update gha_repos set repo_group = 'fluentd' where name in ('fluentd', 'fluent/fluentd');
update gha_repos set repo_group = 'fluent-logger-ruby' where name in ('fluent-logger-ruby', 'fluent/fluent-logger-ruby');
update gha_repos set repo_group = 'fluent-plugin-scribe' where name in ('fluent-plugin-scribe', 'fluent/fluent-plugin-scribe');
update gha_repos set repo_group = 'fluent-plugin-mongo' where name in ('fluent-plugin-mongo', 'fluent/fluent-plugin-mongo');
update gha_repos set repo_group = 'fluent-plugin-s3' where name in ('fluent-plugin-s3', 'fluent/fluent-plugin-s3');
update gha_repos set repo_group = 'fluent-plugin-msgpack-rpc' where name in ('fluent-plugin-msgpack-rpc', 'fluent/fluent-plugin-msgpack-rpc');
update gha_repos set repo_group = 'fluent-logger-python' where name in ('fluent-logger-python', 'fluent/fluent-logger-python');
update gha_repos set repo_group = 'fluent-logger-java' where name in ('fluent-logger-java', 'fluent/fluent-logger-java');
update gha_repos set repo_group = 'fluent-logger-php' where name in ('fluent-logger-php', 'fluent/fluent-logger-php');
update gha_repos set repo_group = 'website' where name in ('website', 'fluent/website');
update gha_repos set repo_group = 'fluent-logger-perl' where name in ('fluent-logger-perl', 'fluent/fluent-logger-perl');
update gha_repos set repo_group = 'fluent-plugin-hoop' where name in ('fluent-plugin-hoop', 'fluent/fluent-plugin-hoop');
update gha_repos set repo_group = 'fluent-logger-d' where name in ('fluent-logger-d', 'fluent/fluent-logger-d');
update gha_repos set repo_group = 'fluent-plugins' where name in ('fluent-plugins', 'fluent/fluent-plugins');
update gha_repos set repo_group = 'fluent-plugin-flume' where name in ('fluent-plugin-flume', 'fluent/fluent-plugin-flume');
update gha_repos set repo_group = 'fluent-plugin-webhdfs' where name in ('fluent-plugin-webhdfs', 'fluent/fluent-plugin-webhdfs');
update gha_repos set repo_group = 'fluent-plugin-sql' where name in ('fluent-plugin-sql', 'fluent/fluent-plugin-sql');
update gha_repos set repo_group = 'nginx-fluentd-module' where name in ('nginx-fluentd-module', 'fluent/nginx-fluentd-module');
update gha_repos set repo_group = 'fluentd-docs' where name in ('fluentd-docs', 'fluent/fluentd-docs');
update gha_repos set repo_group = 'fluent-logger-node' where name in ('fluent-logger-node', 'fluent/fluent-logger-node');
update gha_repos set repo_group = 'fluentd-benchmark' where name in ('fluentd-benchmark', 'fluent/fluentd-benchmark');
update gha_repos set repo_group = 'fluent-plugin-rewrite-tag-filter' where name in ('fluent-plugin-rewrite-tag-filter', 'fluent/fluent-plugin-rewrite-tag-filter');
update gha_repos set repo_group = 'serverengine' where name in ('serverengine', 'fluent/serverengine');
update gha_repos set repo_group = 'fluent-logger-ocaml' where name in ('fluent-logger-ocaml', 'fluent/fluent-logger-ocaml');
update gha_repos set repo_group = 'fluentd-ui' where name in ('fluentd-ui', 'fluent/fluentd-ui');
update gha_repos set repo_group = 'NLog.Targets.Fluentd' where name in ('NLog.Targets.Fluentd', 'fluent/NLog.Targets.Fluentd');
update gha_repos set repo_group = 'fluentd-forwarder' where name in ('fluentd-forwarder', 'fluent/fluentd-forwarder');
update gha_repos set repo_group = 'fluent-bit' where name in ('fluent/fluent-bit', 'fluent-bit');
update gha_repos set repo_group = 'fluent-logger-scala' where name in ('fluent/fluent-logger-scala', 'fluent-logger-scala');
update gha_repos set repo_group = 'fluent-bit-demo' where name in ('fluent/fluent-bit-demo', 'fluent-bit-demo');
update gha_repos set repo_group = 'fluent-logger-erlang' where name in ('fluent/fluent-logger-erlang', 'fluent-logger-erlang');
update gha_repos set repo_group = 'data-collection' where name in ('fluent/data-collection', 'data-collection');
update gha_repos set repo_group = 'fluent-logger-golang' where name in ('fluent/fluent-logger-golang', 'fluent-logger-golang');
update gha_repos set repo_group = 'fluentd-docker-image' where name in ('fluent/fluentd-docker-image', 'fluentd-docker-image');
update gha_repos set repo_group = 'fluent-bit-website' where name in ('fluent/fluent-bit-website', 'fluent-bit-website');
update gha_repos set repo_group = 'fluentbit-dashboard' where name in ('fluent/fluentbit-dashboard', 'fluentbit-dashboard');
update gha_repos set repo_group = 'fluentd-website' where name in ('fluent/fluentd-website', 'fluentd-website');
update gha_repos set repo_group = 'fluentbit-website-v2' where name in ('fluent/fluentbit-website-v2', 'fluentbit-website-v2');
update gha_repos set repo_group = 'fluent-bit-docs' where name in ('fluent/fluent-bit-docs', 'fluent-bit-docs');
update gha_repos set repo_group = 'fluent-bit-go' where name in ('fluent/fluent-bit-go', 'fluent-bit-go');
update gha_repos set repo_group = 'fluent-bit-docker-image' where name in ('fluent/fluent-bit-docker-image', 'fluent-bit-docker-image');
update gha_repos set repo_group = 'fluentd-kubernetes-daemonset' where name in ('fluent/fluentd-kubernetes-daemonset', 'fluentd-kubernetes-daemonset');
update gha_repos set repo_group = 'fluentd-docs-kubernetes' where name in ('fluent/fluentd-docs-kubernetes', 'fluentd-docs-kubernetes');
update gha_repos set repo_group = 'fluent-bit-kubernetes-logging' where name in ('fluent/fluent-bit-kubernetes-logging', 'fluent-bit-kubernetes-logging');
update gha_repos set repo_group = 'fluent-bit-docker-image' where name in ('fluent/fluent-bit-docker-image', 'fluent-bit-docker-image');
update gha_repos set repo_group = 'fluent-bit-packaging' where name in ('fluent/fluent-bit-packaging', 'fluent-bit-packaging');
update gha_repos set repo_group = 'fluent-bit-test' where name in ('fluent/fluent-bit-test', 'fluent-bit-test');
update gha_repos set repo_group = 'kafka-connect-fluentd' where name in ('fluent/kafka-connect-fluentd', 'kafka-connect-fluentd');
update gha_repos set repo_group = 'fluent-bit-kubernetes-logging' where name in ('fluent/fluent-bit-kubernetes-logging', 'fluent-bit-kubernetes-logging');
update gha_repos set repo_group = 'fluentd-docs-gitbook' where name in ('fluent/fluentd-docs-gitbook', 'fluentd-docs-gitbook');
update gha_repos set repo_group = 'fluent-bit-tutorials' where name in ('fluent/fluent-bit-tutorials', 'fluent-bit-tutorials');
update gha_repos set repo_group = 'fluent.github.com' where name in ('fluent/fluent.github.com', 'fluent.github.com');
update gha_repos set repo_group = 'fluent-bit-docs-stream-processing' where name in ('fluent/fluent-bit-docs-stream-processing', 'fluent-bit-docs-stream-processing');
update gha_repos set repo_group = 'fluent-bit-plugin' where name in ('fluent/fluent-bit-plugin', 'fluent-bit-plugin');
update gha_repos set repo_group = 'fluent-bit-perf' where name in ('fluent/fluent-bit-perf', 'fluent-bit-perf');
update gha_repos set repo_group = 'fluent-bit-docker' where name in ('fluent/fluent-bit-docker', 'fluent-bit-docker');
update gha_repos set repo_group = 'fluent-bit-kubernetes-daemonset' where name in ('fluent/fluent-bit-kubernetes-daemonset', 'fluent-bit-kubernetes-daemonset');

update
  gha_repos
set
  repo_group = 'Plugins'
where
  lower(org_login) in (
    'fluent-plugins-nursery'
  )
  or lower(name) in (
    'baritolog/barito-fluent-plugin', 'blacknight95/aws-fluent-plugin-kinesis', 'sumologic/fluentd-kubernetes-sumologic', 'sumologic/fluentd-output-sumologic',
    'wallynegima/scenario-manager-plugin', 'aliyun/aliyun-odps-fluentd-plugin', 'awslabs/aws-fluent-plugin-kinesis', 'campanja/fluent-output-router',
    'grafana/loki/', 'jdoconnor/fluentd_https_out', 'newrelic/newrelic-fluentd-output', 'roma42427/filter_wms_auth', 'scalyr/scalyr-fluentd',
    'sebryu/fluent_plugin_in_websocket', 'tagomoris/fluent-helper-plugin-spec', 'y-ken/fluent-mixin-rewrite-tag-name', 'y-ken/fluent-mixin-type-converter'
  )
  or lower(name) like '%_/fluent-plugin-%'
  or lower(name) like '%_/fluentd-plugin-%'
;

select
  repo_group,
  count(*) as number_of_repos
from
  gha_repos
where
  repo_group is not null
group by
  repo_group
order by
  number_of_repos desc,
  repo_group asc;
