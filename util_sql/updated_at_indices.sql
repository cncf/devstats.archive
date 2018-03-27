create index comments_updated_at_idx on gha_comments(updated_at);
create index issues_updated_at_idx on gha_issues(updated_at);
create index milestones_updated_at_idx on gha_milestones(updated_at);
create index forkees_updated_at_idx on gha_forkees(updated_at);
create index assets_updated_at_idx on gha_assets(updated_at);
create index pull_requests_updated_at_idx on gha_pull_requests(updated_at);
