-- Add repository groups
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

update gha_repos
set repo_group = 'gnatsd', alias = 'gnatsd'
where name in (
  'nats-io/gnatsd',
  'apcera/gnatsd',
  'gnatsd'
);

update gha_repos
set repo_group = 'go-nats', alias = 'go-nats'
where name in (
  'nats-io/go-nats',
  'apcera/nats',
  'nats'
);

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
