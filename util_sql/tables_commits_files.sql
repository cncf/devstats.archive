drop table if exists gha_commits_files;
drop table if exists gha_events_commits_files;
drop table if exists gha_skip_commits;
drop table if exists gha_postprocess_scripts;

CREATE TABLE gha_commits_files (
    sha character varying(40) NOT NULL,
    path text NOT NULL,
    ext text NOT NULL default '',
    size bigint NOT NULL,
    dt timestamp without time zone NOT NULL
);
ALTER TABLE gha_commits_files OWNER TO gha_admin;
ALTER TABLE ONLY gha_commits_files ADD CONSTRAINT gha_commits_files_pkey PRIMARY KEY (sha, path);
CREATE INDEX commits_files_path_idx ON gha_commits_files USING btree (path);
CREATE INDEX commits_files_ext_idx ON gha_commits_files USING btree (ext);
CREATE INDEX commits_files_sha_idx ON gha_commits_files USING btree (sha);
CREATE INDEX commits_files_dt_idx ON gha_commits_files USING btree (dt);
CREATE INDEX commits_files_size_idx ON gha_commits_files USING btree (size);

CREATE TABLE gha_events_commits_files (
    sha character varying(40) NOT NULL,
    event_id bigint NOT NULL,
    path text NOT NULL,
    ext text NOT NULL default '',
    size bigint NOT NULL,
    dt timestamp without time zone NOT NULL,
    repo_group character varying(80),
    dup_repo_id bigint NOT NULL,
    dup_repo_name character varying(160) NOT NULL,
    dup_type character varying(40) NOT NULL,
    dup_created_at timestamp without time zone NOT NULL
);
ALTER TABLE gha_events_commits_files OWNER TO gha_admin;
ALTER TABLE ONLY gha_events_commits_files ADD CONSTRAINT gha_events_commits_files_pkey PRIMARY KEY (sha, event_id, path);
CREATE INDEX events_commits_files_dup_created_at_idx ON gha_events_commits_files USING btree (dup_created_at);
CREATE INDEX events_commits_files_dup_repo_id_idx ON gha_events_commits_files USING btree (dup_repo_id);
CREATE INDEX events_commits_files_dup_repo_name_idx ON gha_events_commits_files USING btree (dup_repo_name);
CREATE INDEX events_commits_files_dup_type_idx ON gha_events_commits_files USING btree (dup_type);
CREATE INDEX events_commits_files_event_id_idx ON gha_events_commits_files USING btree (event_id);
CREATE INDEX events_commits_files_path_idx ON gha_events_commits_files USING btree (path);
CREATE INDEX events_commits_files_ext_idx ON gha_events_commits_files USING btree (ext);
CREATE INDEX events_commits_files_repo_group_idx ON gha_events_commits_files USING btree (repo_group);
CREATE INDEX events_commits_files_sha_idx ON gha_events_commits_files USING btree (sha);
CREATE INDEX events_commits_files_dt_idx ON gha_events_commits_files USING btree (dt);
CREATE INDEX events_commits_files_size_idx ON gha_events_commits_files USING btree (size);

CREATE TABLE gha_skip_commits (
  sha character varying(40) NOT NULL
);
ALTER TABLE gha_skip_commits OWNER TO gha_admin;
ALTER TABLE ONLY gha_skip_commits ADD CONSTRAINT gha_skip_commits_pkey PRIMARY KEY (sha);
CREATE INDEX skip_commits_sha_idx ON gha_skip_commits USING btree (sha);

CREATE TABLE gha_postprocess_scripts (
  ord integer NOT NULL,
  path text NOT NULL
);
ALTER TABLE gha_postprocess_scripts OWNER TO gha_admin;
ALTER TABLE ONLY gha_postprocess_scripts ADD CONSTRAINT gha_postprocess_scripts_pkey PRIMARY KEY (ord, path);
