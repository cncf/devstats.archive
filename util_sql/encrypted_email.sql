alter table gha_commits add encrypted_email varchar(160);
update gha_commits set encrypted_email = author_name;
alter table gha_commits alter column encrypted_email set not null;
create index commits_sha_idx on gha_commits(sha);
create index commits_author_name_idx on gha_commits(author_name);
create index commits_encrypted_email_idx on gha_commits(encrypted_email);
