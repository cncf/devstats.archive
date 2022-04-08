select 'actors' as name, count(*) as count_value from gha_actors union
select 'actors_emails' as name, count(*) as count_value from gha_actors_emails union
select 'actors_affiliations' as name, count(*) as count_value from gha_actors_affiliations union
select 'assets' as name, count(*) as count_value from gha_assets union
select 'branches' as name, count(*) as count_value from gha_branches union
select 'comments' as name, count(*) as count_value from gha_comments union
select 'reviews' as name, count(*) as count_value from gha_reviews union
select 'commits' as name, count(*) as count_value from gha_commits union
select 'commits files' as name, count(*) as count_value from gha_commits_files union
select 'companies' as name, count(*) as count_value from gha_companies union
select 'events' as name, count(*) as count_value from gha_events union
select 'events commits file' as name, count(*) as count_value from gha_events_commits_files union
select 'forkees' as name, count(*) as count_value from gha_forkees union
select 'issues' as name, count(*) as count_value from gha_issues union
select 'issue assignees' as name, count(*) as count_value from gha_issues_assignees union
select 'issue labels' as name, count(*) as count_value from gha_issues_labels union
select 'labels' as name, count(*) as count_value from gha_labels union
select 'milestones' as name, count(*) as count_value from gha_milestones union
select 'orgs' as name, count(*) as count_value from gha_orgs union
select 'pages' as name, count(*) as count_value from gha_pages union
select 'payloads' as name, count(*) as count_value from gha_payloads union
select 'postprocess scripts' as name, count(*) as count_value from gha_postprocess_scripts union
select 'pull requests' as name, count(*) as count_value from gha_pull_requests union
select 'pull request assignees' as name, count(*) as count_value from gha_pull_requests_assignees union
select 'pull request requested reviewers' as name, count(*) as count_value from gha_pull_requests_requested_reviewers union
select 'releases' as name, count(*) as count_value from gha_releases union
select 'release assets' as name, count(*) as count_value from gha_releases_assets union
select 'repos' as name, count(*) as count_value from gha_repos union
select 'skip commits' as name, count(*) as count_value from gha_skip_commits union
select 'teams' as name, count(*) as count_value from gha_teams union
select 'team repositories' as name, count(*) as count_value from gha_teams_repositories union
select 'issue events labels' as name, count(*) as count_value from gha_issues_events_labels union
select 'issue pull requests' as name, count(*) as count_value from gha_issues_pull_requests union
select 'texts' as name, count(*) as count_value from gha_texts union
select 'logs' as name, count(*) as count_value from gha_logs
order by name
