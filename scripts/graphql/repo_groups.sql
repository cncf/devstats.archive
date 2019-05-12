-- Add repository groups

update gha_repos set alias = null, repo_group = null;
update gha_repos set alias = 'GraphQL JavaScript', repo_group = 'GraphQL JavaScript' where name = 'graphql/graphql-js';
update gha_repos set alias = 'GraphQL IDE', repo_group = 'GraphQL IDE' where name = 'graphql/graphiql';
update gha_repos set alias = 'Express GraphQL', repo_group = 'Express GraphQL' where name = 'graphql/express-graphql';
update gha_repos set alias = 'GraphQL Spec', repo_group = 'GraphQL Spec' where name in ('graphql/graphql-spec', 'facebook/graphql');

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
