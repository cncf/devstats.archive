alter table gha_commits add author_email varchar(160) not null default '';
alter table gha_commits add committer_name varchar(160) not null default '';
alter table gha_commits add committer_email varchar(160) not null default '';
alter table gha_commits add author_id bigint;
alter table gha_commits add committer_id bigint;
create index commits_author_email_idx on gha_commits(author_email);
create index commits_committers_name_idx on gha_commits(committer_name);
create index commits_committers_email_idx on gha_commits(committer_email);
create index commits_author_id_idx on gha_commits(author_id);
create index commits_committer_id_idx on gha_commits(committer_id);
create table public.gha_actors_names (
  actor_id bigint not null,
  name varchar(120) not null,
  primary key(actor_id, name)
);
alter table public.gha_actors_names owner to gha_admin;
create index actors_names_actor_id_idx on gha_actors_names(actor_id);
create index actors_names_email_idx on gha_actors_names(name);
