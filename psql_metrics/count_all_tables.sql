select 'actors' as name, count(*) as count_value from gha_actors union
select 'assets' as name, count(*) as count_value from gha_assets union
select 'branches' as name, count(*) as count_value from gha_branches union
select 'comments' as name, count(*) as count_value from gha_comments union
select 'commits' as name, count(*) as count_value from gha_commits union
select 'events' as name, count(*) as count_value from gha_events union
select 'forkees' as name, count(*) as count_value from gha_forkees union
select 'issues' as name, count(*) as count_value from gha_issues union
select 'issue assignees' as name, count(*) as count_value from gha_issues_assignees union
select 'issue events labels' as name, count(*) as count_value from gha_issues_events_labels union
select 'issue labels' as name, count(*) as count_value from gha_issues_labels union
select 'labels' as name, count(*) as count_value from gha_labels union
select 'milestones' as name, count(*) as count_value from gha_milestones union
select 'orgs' as name, count(*) as count_value from gha_orgs union
select 'pages' as name, count(*) as count_value from gha_pages union
select 'payloads' as name, count(*) as count_value from gha_payloads union
select 'pull requests' as name, count(*) as count_value from gha_pull_requests union
select 'pull request assignees' as name, count(*) as count_value from gha_pull_requests_assignees union
select 'pull request requested reviewers' as name, count(*) as count_value from gha_pull_requests_requested_reviewers union
select 'releases' as name, count(*) as count_value from gha_releases union
select 'release assets' as name, count(*) as count_value from gha_releases_assets union
select 'repos' as name, count(*) as count_value from gha_repos union
select 'texts' as name, count(*) as count_value from gha_texts
order by name
