--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.4
-- Dumped by pg_dump version 9.6.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: gha_actors; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_actors (
    id bigint NOT NULL,
    login character varying(120) NOT NULL
);


ALTER TABLE gha_actors OWNER TO gha_admin;

--
-- Name: gha_assets; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_assets (
    id bigint NOT NULL,
    event_id bigint NOT NULL,
    name character varying(200) NOT NULL,
    label character varying(120),
    uploader_id bigint NOT NULL,
    content_type character varying(80) NOT NULL,
    state character varying(20) NOT NULL,
    size integer NOT NULL,
    download_count integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE gha_assets OWNER TO gha_admin;

--
-- Name: gha_branches; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_branches (
    sha character varying(40) NOT NULL,
    event_id bigint NOT NULL,
    user_id bigint,
    repo_id bigint,
    label character varying(200) NOT NULL,
    ref character varying(200) NOT NULL
);


ALTER TABLE gha_branches OWNER TO gha_admin;

--
-- Name: gha_comments; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_comments (
    id bigint NOT NULL,
    event_id bigint NOT NULL,
    body text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    type character varying(40) NOT NULL,
    user_id bigint NOT NULL,
    commit_id character varying(40),
    original_commit_id character varying(40),
    diff_hunk text,
    "position" integer,
    original_position integer,
    path text,
    pull_request_review_id bigint,
    line integer
);


ALTER TABLE gha_comments OWNER TO gha_admin;

--
-- Name: gha_commits; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_commits (
    sha character varying(40) NOT NULL,
    event_id bigint NOT NULL,
    author_name character varying(160) NOT NULL,
    message text NOT NULL,
    is_distinct boolean NOT NULL
);


ALTER TABLE gha_commits OWNER TO gha_admin;

--
-- Name: gha_events; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_events (
    id bigint NOT NULL,
    type character varying(40) NOT NULL,
    actor_id bigint NOT NULL,
    repo_id bigint NOT NULL,
    public boolean NOT NULL,
    created_at timestamp without time zone NOT NULL,
    org_id bigint,
    actor_login character varying(120) NOT NULL,
    repo_name character varying(160) NOT NULL
);


ALTER TABLE gha_events OWNER TO gha_admin;

--
-- Name: gha_events_commits; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_events_commits (
    event_id bigint NOT NULL,
    sha character varying(40) NOT NULL
);


ALTER TABLE gha_events_commits OWNER TO gha_admin;

--
-- Name: gha_events_pages; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_events_pages (
    event_id bigint NOT NULL,
    sha character varying(40) NOT NULL
);


ALTER TABLE gha_events_pages OWNER TO gha_admin;

--
-- Name: gha_forkees; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_forkees (
    id bigint NOT NULL,
    event_id bigint NOT NULL,
    name character varying(80) NOT NULL,
    full_name character varying(200) NOT NULL,
    owner_id bigint NOT NULL,
    description text,
    fork boolean NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    pushed_at timestamp without time zone NOT NULL,
    homepage text,
    size integer NOT NULL,
    stargazers_count integer NOT NULL,
    has_issues boolean NOT NULL,
    has_projects boolean,
    has_downloads boolean NOT NULL,
    has_wiki boolean NOT NULL,
    has_pages boolean,
    forks integer NOT NULL,
    open_issues integer NOT NULL,
    watchers integer NOT NULL,
    default_branch character varying(200) NOT NULL,
    public boolean
);


ALTER TABLE gha_forkees OWNER TO gha_admin;

--
-- Name: gha_issues; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_issues (
    id bigint NOT NULL,
    event_id bigint NOT NULL,
    assignee_id bigint,
    body text,
    closed_at timestamp without time zone,
    comments integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    locked boolean NOT NULL,
    milestone_id bigint,
    number integer NOT NULL,
    state character varying(20) NOT NULL,
    title text NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id bigint NOT NULL,
    is_pull_request boolean NOT NULL
);


ALTER TABLE gha_issues OWNER TO gha_admin;

--
-- Name: gha_issues_assignees; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_issues_assignees (
    issue_id bigint NOT NULL,
    event_id bigint NOT NULL,
    assignee_id bigint NOT NULL
);


ALTER TABLE gha_issues_assignees OWNER TO gha_admin;

--
-- Name: gha_issues_events_labels; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_issues_events_labels (
    issue_id bigint NOT NULL,
    event_id bigint NOT NULL,
    label_id bigint NOT NULL,
    label_name character varying(160) NOT NULL,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE gha_issues_events_labels OWNER TO gha_admin;

--
-- Name: gha_issues_labels; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_issues_labels (
    issue_id bigint NOT NULL,
    event_id bigint NOT NULL,
    label_id bigint NOT NULL
);


ALTER TABLE gha_issues_labels OWNER TO gha_admin;

--
-- Name: gha_labels; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_labels (
    id bigint NOT NULL,
    name character varying(160) NOT NULL,
    color character varying(8) NOT NULL,
    is_default boolean
);


ALTER TABLE gha_labels OWNER TO gha_admin;

--
-- Name: gha_milestones; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_milestones (
    id bigint NOT NULL,
    event_id bigint NOT NULL,
    closed_at timestamp without time zone,
    closed_issues integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    creator_id bigint,
    description text,
    due_on timestamp without time zone,
    number integer NOT NULL,
    open_issues integer NOT NULL,
    state character varying(20) NOT NULL,
    title character varying(200) NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE gha_milestones OWNER TO gha_admin;

--
-- Name: gha_orgs; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_orgs (
    id bigint NOT NULL,
    login character varying(100) NOT NULL
);


ALTER TABLE gha_orgs OWNER TO gha_admin;

--
-- Name: gha_pages; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_pages (
    sha character varying(40) NOT NULL,
    event_id bigint NOT NULL,
    action character varying(20) NOT NULL,
    title character varying(300) NOT NULL
);


ALTER TABLE gha_pages OWNER TO gha_admin;

--
-- Name: gha_payloads; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_payloads (
    event_id bigint NOT NULL,
    push_id integer,
    size integer,
    ref character varying(200),
    head character varying(40),
    befor character varying(40),
    action character varying(20),
    issue_id bigint,
    comment_id bigint,
    ref_type character varying(20),
    master_branch character varying(200),
    description text,
    number integer,
    forkee_id bigint,
    release_id bigint,
    member_id bigint
);


ALTER TABLE gha_payloads OWNER TO gha_admin;

--
-- Name: gha_pull_requests; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_pull_requests (
    id bigint NOT NULL,
    event_id bigint NOT NULL,
    user_id bigint NOT NULL,
    base_sha character varying(40) NOT NULL,
    head_sha character varying(40) NOT NULL,
    merged_by_id bigint,
    assignee_id bigint,
    milestone_id bigint,
    number integer NOT NULL,
    state character varying(20) NOT NULL,
    locked boolean NOT NULL,
    title text NOT NULL,
    body text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    closed_at timestamp without time zone,
    merged_at timestamp without time zone,
    merge_commit_sha character varying(40),
    merged boolean,
    mergeable boolean,
    rebaseable boolean,
    mergeable_state character varying(20),
    comments integer,
    review_comments integer,
    maintainer_can_modify boolean,
    commits integer,
    additions integer,
    deletions integer,
    changed_files integer
);


ALTER TABLE gha_pull_requests OWNER TO gha_admin;

--
-- Name: gha_pull_requests_assignees; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_pull_requests_assignees (
    pull_request_id bigint NOT NULL,
    event_id bigint NOT NULL,
    assignee_id bigint NOT NULL
);


ALTER TABLE gha_pull_requests_assignees OWNER TO gha_admin;

--
-- Name: gha_pull_requests_requested_reviewers; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_pull_requests_requested_reviewers (
    pull_request_id bigint NOT NULL,
    event_id bigint NOT NULL,
    requested_reviewer_id bigint NOT NULL
);


ALTER TABLE gha_pull_requests_requested_reviewers OWNER TO gha_admin;

--
-- Name: gha_releases; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_releases (
    id bigint NOT NULL,
    event_id bigint NOT NULL,
    tag_name character varying(200) NOT NULL,
    target_commitish character varying(200) NOT NULL,
    name character varying(200),
    draft boolean NOT NULL,
    author_id bigint NOT NULL,
    prerelease boolean NOT NULL,
    created_at timestamp without time zone NOT NULL,
    published_at timestamp without time zone NOT NULL,
    body text
);


ALTER TABLE gha_releases OWNER TO gha_admin;

--
-- Name: gha_releases_assets; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_releases_assets (
    release_id bigint NOT NULL,
    event_id bigint NOT NULL,
    asset_id bigint NOT NULL
);


ALTER TABLE gha_releases_assets OWNER TO gha_admin;

--
-- Name: gha_repos; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_repos (
    id bigint NOT NULL,
    name character varying(160) NOT NULL
);


ALTER TABLE gha_repos OWNER TO gha_admin;

--
-- Name: gha_texts; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_texts (
    event_id bigint,
    body text,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE gha_texts OWNER TO gha_admin;

--
-- Data for Name: gha_actors; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_actors (id, login) FROM stdin;
\.


--
-- Data for Name: gha_assets; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_assets (id, event_id, name, label, uploader_id, content_type, state, size, download_count, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: gha_branches; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_branches (sha, event_id, user_id, repo_id, label, ref) FROM stdin;
\.


--
-- Data for Name: gha_comments; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_comments (id, event_id, body, created_at, updated_at, type, user_id, commit_id, original_commit_id, diff_hunk, "position", original_position, path, pull_request_review_id, line) FROM stdin;
\.


--
-- Data for Name: gha_commits; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_commits (sha, event_id, author_name, message, is_distinct) FROM stdin;
\.


--
-- Data for Name: gha_events; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_events (id, type, actor_id, repo_id, public, created_at, org_id, actor_login, repo_name) FROM stdin;
\.


--
-- Data for Name: gha_events_commits; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_events_commits (event_id, sha) FROM stdin;
\.


--
-- Data for Name: gha_events_pages; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_events_pages (event_id, sha) FROM stdin;
\.


--
-- Data for Name: gha_forkees; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_forkees (id, event_id, name, full_name, owner_id, description, fork, created_at, updated_at, pushed_at, homepage, size, stargazers_count, has_issues, has_projects, has_downloads, has_wiki, has_pages, forks, open_issues, watchers, default_branch, public) FROM stdin;
\.


--
-- Data for Name: gha_issues; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_issues (id, event_id, assignee_id, body, closed_at, comments, created_at, locked, milestone_id, number, state, title, updated_at, user_id, is_pull_request) FROM stdin;
\.


--
-- Data for Name: gha_issues_assignees; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_issues_assignees (issue_id, event_id, assignee_id) FROM stdin;
\.


--
-- Data for Name: gha_issues_events_labels; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_issues_events_labels (issue_id, event_id, label_id, label_name, created_at) FROM stdin;
\.


--
-- Data for Name: gha_issues_labels; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_issues_labels (issue_id, event_id, label_id) FROM stdin;
\.


--
-- Data for Name: gha_labels; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_labels (id, name, color, is_default) FROM stdin;
\.


--
-- Data for Name: gha_milestones; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_milestones (id, event_id, closed_at, closed_issues, created_at, creator_id, description, due_on, number, open_issues, state, title, updated_at) FROM stdin;
\.


--
-- Data for Name: gha_orgs; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_orgs (id, login) FROM stdin;
\.


--
-- Data for Name: gha_pages; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_pages (sha, event_id, action, title) FROM stdin;
\.


--
-- Data for Name: gha_payloads; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_payloads (event_id, push_id, size, ref, head, befor, action, issue_id, comment_id, ref_type, master_branch, description, number, forkee_id, release_id, member_id) FROM stdin;
\.


--
-- Data for Name: gha_pull_requests; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_pull_requests (id, event_id, user_id, base_sha, head_sha, merged_by_id, assignee_id, milestone_id, number, state, locked, title, body, created_at, updated_at, closed_at, merged_at, merge_commit_sha, merged, mergeable, rebaseable, mergeable_state, comments, review_comments, maintainer_can_modify, commits, additions, deletions, changed_files) FROM stdin;
\.


--
-- Data for Name: gha_pull_requests_assignees; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_pull_requests_assignees (pull_request_id, event_id, assignee_id) FROM stdin;
\.


--
-- Data for Name: gha_pull_requests_requested_reviewers; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_pull_requests_requested_reviewers (pull_request_id, event_id, requested_reviewer_id) FROM stdin;
\.


--
-- Data for Name: gha_releases; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_releases (id, event_id, tag_name, target_commitish, name, draft, author_id, prerelease, created_at, published_at, body) FROM stdin;
\.


--
-- Data for Name: gha_releases_assets; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_releases_assets (release_id, event_id, asset_id) FROM stdin;
\.


--
-- Data for Name: gha_repos; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_repos (id, name) FROM stdin;
\.


--
-- Data for Name: gha_texts; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_texts (event_id, body, created_at) FROM stdin;
\.


--
-- Name: gha_actors gha_actors_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_actors
    ADD CONSTRAINT gha_actors_pkey PRIMARY KEY (id);


--
-- Name: gha_assets gha_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_assets
    ADD CONSTRAINT gha_assets_pkey PRIMARY KEY (id, event_id);


--
-- Name: gha_branches gha_branches_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_branches
    ADD CONSTRAINT gha_branches_pkey PRIMARY KEY (sha, event_id);


--
-- Name: gha_comments gha_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_comments
    ADD CONSTRAINT gha_comments_pkey PRIMARY KEY (id);


--
-- Name: gha_commits gha_commits_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_commits
    ADD CONSTRAINT gha_commits_pkey PRIMARY KEY (sha, event_id);


--
-- Name: gha_events_commits gha_events_commits_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_events_commits
    ADD CONSTRAINT gha_events_commits_pkey PRIMARY KEY (event_id, sha);


--
-- Name: gha_events_pages gha_events_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_events_pages
    ADD CONSTRAINT gha_events_pages_pkey PRIMARY KEY (event_id, sha);


--
-- Name: gha_events gha_events_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_events
    ADD CONSTRAINT gha_events_pkey PRIMARY KEY (id);


--
-- Name: gha_forkees gha_forkees_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_forkees
    ADD CONSTRAINT gha_forkees_pkey PRIMARY KEY (id, event_id);


--
-- Name: gha_issues_assignees gha_issues_assignees_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_issues_assignees
    ADD CONSTRAINT gha_issues_assignees_pkey PRIMARY KEY (issue_id, event_id, assignee_id);


--
-- Name: gha_issues_labels gha_issues_labels_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_issues_labels
    ADD CONSTRAINT gha_issues_labels_pkey PRIMARY KEY (issue_id, event_id, label_id);


--
-- Name: gha_issues gha_issues_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_issues
    ADD CONSTRAINT gha_issues_pkey PRIMARY KEY (id, event_id);


--
-- Name: gha_labels gha_labels_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_labels
    ADD CONSTRAINT gha_labels_pkey PRIMARY KEY (id);


--
-- Name: gha_milestones gha_milestones_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_milestones
    ADD CONSTRAINT gha_milestones_pkey PRIMARY KEY (id, event_id);


--
-- Name: gha_orgs gha_orgs_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_orgs
    ADD CONSTRAINT gha_orgs_pkey PRIMARY KEY (id);


--
-- Name: gha_pages gha_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_pages
    ADD CONSTRAINT gha_pages_pkey PRIMARY KEY (sha, event_id, action, title);


--
-- Name: gha_payloads gha_payloads_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_payloads
    ADD CONSTRAINT gha_payloads_pkey PRIMARY KEY (event_id);


--
-- Name: gha_pull_requests_assignees gha_pull_requests_assignees_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_pull_requests_assignees
    ADD CONSTRAINT gha_pull_requests_assignees_pkey PRIMARY KEY (pull_request_id, event_id, assignee_id);


--
-- Name: gha_pull_requests gha_pull_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_pull_requests
    ADD CONSTRAINT gha_pull_requests_pkey PRIMARY KEY (id, event_id);


--
-- Name: gha_pull_requests_requested_reviewers gha_pull_requests_requested_reviewers_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_pull_requests_requested_reviewers
    ADD CONSTRAINT gha_pull_requests_requested_reviewers_pkey PRIMARY KEY (pull_request_id, event_id, requested_reviewer_id);


--
-- Name: gha_releases_assets gha_releases_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_releases_assets
    ADD CONSTRAINT gha_releases_assets_pkey PRIMARY KEY (release_id, event_id, asset_id);


--
-- Name: gha_releases gha_releases_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_releases
    ADD CONSTRAINT gha_releases_pkey PRIMARY KEY (id, event_id);


--
-- Name: gha_repos gha_repos_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_repos
    ADD CONSTRAINT gha_repos_pkey PRIMARY KEY (id);


--
-- Name: actors_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX actors_login_idx ON gha_actors USING btree (login);


--
-- Name: assets_content_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_content_type_idx ON gha_assets USING btree (content_type);


--
-- Name: assets_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_created_at_idx ON gha_assets USING btree (created_at);


--
-- Name: assets_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_event_id_idx ON gha_assets USING btree (event_id);


--
-- Name: assets_state_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_state_idx ON gha_assets USING btree (state);


--
-- Name: assets_uploader_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_uploader_id_idx ON gha_assets USING btree (uploader_id);


--
-- Name: branches_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX branches_event_id_idx ON gha_branches USING btree (event_id);


--
-- Name: branches_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX branches_repo_id_idx ON gha_branches USING btree (repo_id);


--
-- Name: branches_user_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX branches_user_id_idx ON gha_branches USING btree (user_id);


--
-- Name: comments_commit_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_commit_id_idx ON gha_comments USING btree (commit_id);


--
-- Name: comments_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_created_at_idx ON gha_comments USING btree (created_at);


--
-- Name: comments_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_event_id_idx ON gha_comments USING btree (event_id);


--
-- Name: comments_pull_request_review_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_pull_request_review_id_idx ON gha_comments USING btree (pull_request_review_id);


--
-- Name: comments_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_type_idx ON gha_comments USING btree (type);


--
-- Name: comments_user_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_user_id_idx ON gha_comments USING btree (user_id);


--
-- Name: commits_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_event_id_idx ON gha_commits USING btree (event_id);


--
-- Name: events_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_actor_id_idx ON gha_events USING btree (actor_id);


--
-- Name: events_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_actor_login_idx ON gha_events USING btree (actor_login);


--
-- Name: events_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_created_at_idx ON gha_events USING btree (created_at);


--
-- Name: events_org_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_org_id_idx ON gha_events USING btree (org_id);


--
-- Name: events_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_repo_id_idx ON gha_events USING btree (repo_id);


--
-- Name: events_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_repo_name_idx ON gha_events USING btree (repo_name);


--
-- Name: events_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_type_idx ON gha_events USING btree (type);


--
-- Name: forkees_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_created_at_idx ON gha_forkees USING btree (created_at);


--
-- Name: forkees_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_event_id_idx ON gha_forkees USING btree (event_id);


--
-- Name: forkees_owner_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_owner_id_idx ON gha_forkees USING btree (owner_id);


--
-- Name: issues_assignee_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_assignee_id_idx ON gha_issues USING btree (assignee_id);


--
-- Name: issues_closed_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_closed_at_idx ON gha_issues USING btree (closed_at);


--
-- Name: issues_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_created_at_idx ON gha_issues USING btree (created_at);


--
-- Name: issues_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_event_id_idx ON gha_issues USING btree (event_id);


--
-- Name: issues_events_labels_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_events_labels_created_at_idx ON gha_issues_events_labels USING btree (created_at);


--
-- Name: issues_events_labels_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_events_labels_event_id_idx ON gha_issues_events_labels USING btree (event_id);


--
-- Name: issues_events_labels_issue_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_events_labels_issue_id_idx ON gha_issues_events_labels USING btree (issue_id);


--
-- Name: issues_events_labels_label_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_events_labels_label_id_idx ON gha_issues_events_labels USING btree (label_id);


--
-- Name: issues_events_labels_label_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_events_labels_label_name_idx ON gha_issues_events_labels USING btree (label_name);


--
-- Name: issues_is_pull_request_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_is_pull_request_idx ON gha_issues USING btree (is_pull_request);


--
-- Name: issues_milestone_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_milestone_id_idx ON gha_issues USING btree (milestone_id);


--
-- Name: issues_state_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_state_idx ON gha_issues USING btree (state);


--
-- Name: issues_user_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_user_id_idx ON gha_issues USING btree (user_id);


--
-- Name: labels_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX labels_name_idx ON gha_labels USING btree (name);


--
-- Name: milestones_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_created_at_idx ON gha_milestones USING btree (created_at);


--
-- Name: milestones_creator_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_creator_id_idx ON gha_milestones USING btree (creator_id);


--
-- Name: milestones_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_event_id_idx ON gha_milestones USING btree (event_id);


--
-- Name: milestones_state_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_state_idx ON gha_milestones USING btree (state);


--
-- Name: orgs_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX orgs_login_idx ON gha_orgs USING btree (login);


--
-- Name: pages_action_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pages_action_idx ON gha_pages USING btree (action);


--
-- Name: pages_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pages_event_id_idx ON gha_pages USING btree (event_id);


--
-- Name: payloads_action_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_action_idx ON gha_payloads USING btree (action);


--
-- Name: payloads_comment_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_comment_id_idx ON gha_payloads USING btree (comment_id);


--
-- Name: payloads_forkee_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_forkee_id_idx ON gha_payloads USING btree (forkee_id);


--
-- Name: payloads_head_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_head_idx ON gha_payloads USING btree (head);


--
-- Name: payloads_issue_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_issue_id_idx ON gha_payloads USING btree (issue_id);


--
-- Name: payloads_member_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_member_id_idx ON gha_payloads USING btree (member_id);


--
-- Name: payloads_ref_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_ref_type_idx ON gha_payloads USING btree (ref_type);


--
-- Name: payloads_release_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_release_id_idx ON gha_payloads USING btree (release_id);


--
-- Name: pull_requests_assignee_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_assignee_id_idx ON gha_pull_requests USING btree (assignee_id);


--
-- Name: pull_requests_base_sha_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_base_sha_idx ON gha_pull_requests USING btree (base_sha);


--
-- Name: pull_requests_closed_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_closed_at_idx ON gha_pull_requests USING btree (closed_at);


--
-- Name: pull_requests_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_created_at_idx ON gha_pull_requests USING btree (created_at);


--
-- Name: pull_requests_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_event_id_idx ON gha_pull_requests USING btree (event_id);


--
-- Name: pull_requests_head_sha_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_head_sha_idx ON gha_pull_requests USING btree (head_sha);


--
-- Name: pull_requests_merged_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_merged_at_idx ON gha_pull_requests USING btree (merged_at);


--
-- Name: pull_requests_merged_by_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_merged_by_id_idx ON gha_pull_requests USING btree (merged_by_id);


--
-- Name: pull_requests_milestone_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_milestone_id_idx ON gha_pull_requests USING btree (milestone_id);


--
-- Name: pull_requests_state_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_state_idx ON gha_pull_requests USING btree (state);


--
-- Name: pull_requests_user_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_user_id_idx ON gha_pull_requests USING btree (user_id);


--
-- Name: releases_author_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX releases_author_id_idx ON gha_releases USING btree (author_id);


--
-- Name: releases_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX releases_created_at_idx ON gha_releases USING btree (created_at);


--
-- Name: releases_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX releases_event_id_idx ON gha_releases USING btree (event_id);


--
-- Name: repos_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX repos_name_idx ON gha_repos USING btree (name);


--
-- Name: texts_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX texts_created_at_idx ON gha_texts USING btree (created_at);


--
-- Name: texts_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX texts_event_id_idx ON gha_texts USING btree (event_id);


--
-- PostgreSQL database dump complete
--

