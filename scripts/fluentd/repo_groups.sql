-- Add repository groups
-- This is a stub, repo_group = repo name in Prometheus
update
  gha_repos r
set
  alias = coalesce((
    select e.dup_repo_name
    from
      gha_events e
    where
      e.repo_id = r.id
    order by
      e.created_at desc
    limit 1
  ), name)
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
