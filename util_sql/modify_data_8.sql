alter table gha_actors_emails add origin smallint not null default 0;
alter table gha_actors_names add origin smallint not null default 0;

update gha_actors_emails set origin = 1 where email in (select committer_email from gha_commits union select author_email from gha_commits) and origin = 0;
update gha_actors_names set origin = 1 where name in (select committer_name from gha_commits union select author_name from gha_commits) and origin = 0;
