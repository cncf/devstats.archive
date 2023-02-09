CREATE TABLE public.gha_commits_roles (
    sha varchar(40) not null,
    event_id bigint not null,
    role varchar(120) not null,
    actor_id bigint,
    actor_login varchar(120) not null default '',
    actor_name varchar(160) not null default '',
    actor_email varchar(160) not null default '',
    dup_repo_id bigint not null,
    dup_repo_name varchar(160) not null,
    dup_created_at timestamp without time zone not null,
    primary key(sha, event_id, role)
);
ALTER TABLE public.gha_commits_roles OWNER TO gha_admin;
grant select on gha_commits_roles to "devstats_team";
grant select on gha_commits_roles to "ro_user";
create index commits_roles_sha_idx on gha_commits_roles(sha);
create index commits_roles_event_id_idx on gha_commits_roles(event_id);
create index commits_roles_role_idx on gha_commits_roles(role);
create index commits_roles_actor_id_idx on gha_commits_roles(actor_id);
create index commits_roles_actor_login_idx on gha_commits_roles(actor_login);
create index commits_roles_actor_name_idx on gha_commits_roles(actor_name);
create index commits_roles_actor_email_idx on gha_commits_roles(actor_email);
create index commits_roles_dup_repo_id_idx on gha_commits_roles(dup_repo_id);
create index commits_roles_dup_repo_name_idx on gha_commits_roles(dup_repo_name);
create index commits_roles_dup_created_at_idx on gha_commits_roles(dup_created_at);
