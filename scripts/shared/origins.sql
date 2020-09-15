update gha_actors_emails set origin = 1 where origin = 0 and email in (select committer_email from gha_commits union select author_email from gha_commits);
update gha_actors_names set origin = 1 where origin = 0 and name in (select committer_name from gha_commits union select author_name from gha_commits);
