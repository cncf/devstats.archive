--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.6
-- Dumped by pg_dump version 9.6.6

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
    login character varying(120) NOT NULL,
    name character varying(120)
);


ALTER TABLE gha_actors OWNER TO gha_admin;

--
-- Name: gha_actors_affiliations; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_actors_affiliations (
    actor_id bigint NOT NULL,
    company_name character varying(160) NOT NULL,
    dt_from timestamp without time zone NOT NULL,
    dt_to timestamp without time zone NOT NULL
);


ALTER TABLE gha_actors_affiliations OWNER TO gha_admin;

--
-- Name: gha_actors_emails; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_actors_emails (
    actor_id bigint NOT NULL,
    email character varying(120) NOT NULL
);


ALTER TABLE gha_actors_emails OWNER TO gha_admin;

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
    updated_at timestamp without time zone NOT NULL,
    dup_actor_id bigint NOT NULL,
    dup_actor_login character varying(120) NOT NULL,
    dup_repo_id bigint NOT NULL,
    dup_repo_name character varying(160) NOT NULL,
    dup_type character varying(40) NOT NULL,
    dup_created_at timestamp without time zone NOT NULL,
    dup_uploader_login character varying(120) NOT NULL
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
    ref character varying(200) NOT NULL,
    dup_type character varying(40) NOT NULL,
    dup_created_at timestamp without time zone NOT NULL,
    dupn_forkee_name character varying(160),
    dupn_user_login character varying(120)
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
    user_id bigint NOT NULL,
    commit_id character varying(40),
    original_commit_id character varying(40),
    diff_hunk text,
    "position" integer,
    original_position integer,
    path text,
    pull_request_review_id bigint,
    line integer,
    dup_actor_id bigint NOT NULL,
    dup_actor_login character varying(120) NOT NULL,
    dup_repo_id bigint NOT NULL,
    dup_repo_name character varying(160) NOT NULL,
    dup_type character varying(40) NOT NULL,
    dup_created_at timestamp without time zone NOT NULL,
    dup_user_login character varying(120) NOT NULL
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
    is_distinct boolean NOT NULL,
    dup_actor_id bigint NOT NULL,
    dup_actor_login character varying(120) NOT NULL,
    dup_repo_id bigint NOT NULL,
    dup_repo_name character varying(160) NOT NULL,
    dup_type character varying(40) NOT NULL,
    dup_created_at timestamp without time zone NOT NULL
);


ALTER TABLE gha_commits OWNER TO gha_admin;

--
-- Name: gha_commits_files; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_commits_files (
    sha character varying(40) NOT NULL,
    path text NOT NULL,
    size bigint NOT NULL,
    dt timestamp without time zone NOT NULL
);


ALTER TABLE gha_commits_files OWNER TO gha_admin;

--
-- Name: gha_companies; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_companies (
    name character varying(160) NOT NULL
);


ALTER TABLE gha_companies OWNER TO gha_admin;

--
-- Name: gha_computed; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_computed (
    metric text NOT NULL,
    dt timestamp without time zone NOT NULL
);


ALTER TABLE gha_computed OWNER TO gha_admin;

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
    forkee_id bigint,
    dup_actor_login character varying(120) NOT NULL,
    dup_repo_name character varying(160) NOT NULL
);


ALTER TABLE gha_events OWNER TO gha_admin;

--
-- Name: gha_events_commits_files; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_events_commits_files (
    sha character varying(40) NOT NULL,
    event_id bigint NOT NULL,
    path text NOT NULL,
    size bigint NOT NULL,
    dt timestamp without time zone NOT NULL,
    repo_group character varying(80),
    dup_repo_id bigint NOT NULL,
    dup_repo_name character varying(160) NOT NULL,
    dup_type character varying(40) NOT NULL,
    dup_created_at timestamp without time zone NOT NULL
);


ALTER TABLE gha_events_commits_files OWNER TO gha_admin;

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
    pushed_at timestamp without time zone,
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
    public boolean,
    language character varying(80),
    organization character varying(100),
    dup_actor_id bigint NOT NULL,
    dup_actor_login character varying(120) NOT NULL,
    dup_repo_id bigint NOT NULL,
    dup_repo_name character varying(160) NOT NULL,
    dup_type character varying(40) NOT NULL,
    dup_created_at timestamp without time zone NOT NULL,
    dup_owner_login character varying(120) NOT NULL
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
    is_pull_request boolean NOT NULL,
    dup_actor_id bigint NOT NULL,
    dup_actor_login character varying(120) NOT NULL,
    dup_repo_id bigint NOT NULL,
    dup_repo_name character varying(160) NOT NULL,
    dup_type character varying(40) NOT NULL,
    dup_created_at timestamp without time zone NOT NULL,
    dupn_assignee_login character varying(120),
    dup_user_login character varying(120) NOT NULL
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
    created_at timestamp without time zone NOT NULL,
    actor_id bigint NOT NULL,
    actor_login character varying(120) NOT NULL,
    repo_id bigint NOT NULL,
    repo_name character varying(160) NOT NULL,
    type character varying(40) NOT NULL,
    issue_number integer NOT NULL
);


ALTER TABLE gha_issues_events_labels OWNER TO gha_admin;

--
-- Name: gha_issues_labels; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_issues_labels (
    issue_id bigint NOT NULL,
    event_id bigint NOT NULL,
    label_id bigint NOT NULL,
    dup_actor_id bigint NOT NULL,
    dup_actor_login character varying(120) NOT NULL,
    dup_repo_id bigint NOT NULL,
    dup_repo_name character varying(160) NOT NULL,
    dup_type character varying(40) NOT NULL,
    dup_created_at timestamp without time zone NOT NULL,
    dup_issue_number integer NOT NULL,
    dup_label_name character varying(160) NOT NULL
);


ALTER TABLE gha_issues_labels OWNER TO gha_admin;

--
-- Name: gha_issues_pull_requests; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_issues_pull_requests (
    issue_id bigint NOT NULL,
    pull_request_id bigint NOT NULL,
    number integer NOT NULL,
    repo_id bigint NOT NULL,
    repo_name character varying(160) NOT NULL,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE gha_issues_pull_requests OWNER TO gha_admin;

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
-- Name: gha_logs; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_logs (
    id integer NOT NULL,
    dt timestamp without time zone DEFAULT now(),
    prog character varying(32) NOT NULL,
    proj character varying(32) NOT NULL,
    run_dt timestamp without time zone NOT NULL,
    msg text
);


ALTER TABLE gha_logs OWNER TO gha_admin;

--
-- Name: gha_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: gha_admin
--

CREATE SEQUENCE gha_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE gha_logs_id_seq OWNER TO gha_admin;

--
-- Name: gha_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gha_admin
--

ALTER SEQUENCE gha_logs_id_seq OWNED BY gha_logs.id;


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
    updated_at timestamp without time zone NOT NULL,
    dup_actor_id bigint NOT NULL,
    dup_actor_login character varying(120) NOT NULL,
    dup_repo_id bigint NOT NULL,
    dup_repo_name character varying(160) NOT NULL,
    dup_type character varying(40) NOT NULL,
    dup_created_at timestamp without time zone NOT NULL,
    dupn_creator_login character varying(120)
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
    title character varying(300) NOT NULL,
    dup_actor_id bigint NOT NULL,
    dup_actor_login character varying(120) NOT NULL,
    dup_repo_id bigint NOT NULL,
    dup_repo_name character varying(160) NOT NULL,
    dup_type character varying(40) NOT NULL,
    dup_created_at timestamp without time zone NOT NULL
);


ALTER TABLE gha_pages OWNER TO gha_admin;

--
-- Name: gha_parsed; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_parsed (
    dt timestamp without time zone NOT NULL
);


ALTER TABLE gha_parsed OWNER TO gha_admin;

--
-- Name: gha_payloads; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_payloads (
    event_id bigint NOT NULL,
    push_id bigint,
    size integer,
    ref character varying(200),
    head character varying(40),
    befor character varying(40),
    action character varying(20),
    issue_id bigint,
    pull_request_id bigint,
    comment_id bigint,
    ref_type character varying(20),
    master_branch character varying(200),
    description text,
    number integer,
    forkee_id bigint,
    release_id bigint,
    member_id bigint,
    commit character varying(40),
    dup_actor_id bigint NOT NULL,
    dup_actor_login character varying(120) NOT NULL,
    dup_repo_id bigint NOT NULL,
    dup_repo_name character varying(160) NOT NULL,
    dup_type character varying(40) NOT NULL,
    dup_created_at timestamp without time zone NOT NULL
);


ALTER TABLE gha_payloads OWNER TO gha_admin;

--
-- Name: gha_postprocess_scripts; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_postprocess_scripts (
    ord integer NOT NULL,
    path text NOT NULL
);


ALTER TABLE gha_postprocess_scripts OWNER TO gha_admin;

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
    locked boolean,
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
    changed_files integer,
    dup_actor_id bigint NOT NULL,
    dup_actor_login character varying(120) NOT NULL,
    dup_repo_id bigint NOT NULL,
    dup_repo_name character varying(160) NOT NULL,
    dup_type character varying(40) NOT NULL,
    dup_created_at timestamp without time zone NOT NULL,
    dup_user_login character varying(120) NOT NULL,
    dupn_assignee_login character varying(120),
    dupn_merged_by_login character varying(120)
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
    published_at timestamp without time zone,
    body text,
    dup_actor_id bigint NOT NULL,
    dup_actor_login character varying(120) NOT NULL,
    dup_repo_id bigint NOT NULL,
    dup_repo_name character varying(160) NOT NULL,
    dup_type character varying(40) NOT NULL,
    dup_created_at timestamp without time zone NOT NULL,
    dup_author_login character varying(120) NOT NULL
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
    name character varying(160) NOT NULL,
    org_id bigint,
    org_login character varying(100),
    repo_group character varying(80),
    alias character varying(160)
);


ALTER TABLE gha_repos OWNER TO gha_admin;

--
-- Name: gha_skip_commits; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_skip_commits (
    sha character varying(40) NOT NULL,
    dt timestamp without time zone NOT NULL
);


ALTER TABLE gha_skip_commits OWNER TO gha_admin;

--
-- Name: gha_teams; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_teams (
    id bigint NOT NULL,
    event_id bigint NOT NULL,
    name character varying(120) NOT NULL,
    slug character varying(100) NOT NULL,
    permission character varying(20) NOT NULL,
    dup_actor_id bigint NOT NULL,
    dup_actor_login character varying(120) NOT NULL,
    dup_repo_id bigint NOT NULL,
    dup_repo_name character varying(160) NOT NULL,
    dup_type character varying(40) NOT NULL,
    dup_created_at timestamp without time zone NOT NULL
);


ALTER TABLE gha_teams OWNER TO gha_admin;

--
-- Name: gha_teams_repositories; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_teams_repositories (
    team_id bigint NOT NULL,
    event_id bigint NOT NULL,
    repository_id bigint NOT NULL
);


ALTER TABLE gha_teams_repositories OWNER TO gha_admin;

--
-- Name: gha_texts; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_texts (
    event_id bigint,
    body text,
    created_at timestamp without time zone NOT NULL,
    actor_id bigint NOT NULL,
    actor_login character varying(120) NOT NULL,
    repo_id bigint NOT NULL,
    repo_name character varying(160) NOT NULL,
    type character varying(40) NOT NULL
);


ALTER TABLE gha_texts OWNER TO gha_admin;

--
-- Name: gha_vars; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_vars (
    name character varying(100) NOT NULL,
    value_i bigint,
    value_f double precision,
    value_s text,
    value_dt timestamp without time zone
);


ALTER TABLE gha_vars OWNER TO gha_admin;

--
-- Name: gha_logs id; Type: DEFAULT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_logs ALTER COLUMN id SET DEFAULT nextval('gha_logs_id_seq'::regclass);


--
-- Name: gha_actors_affiliations gha_actors_affiliations_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_actors_affiliations
    ADD CONSTRAINT gha_actors_affiliations_pkey PRIMARY KEY (actor_id, company_name, dt_from, dt_to);


--
-- Name: gha_actors_emails gha_actors_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_actors_emails
    ADD CONSTRAINT gha_actors_emails_pkey PRIMARY KEY (actor_id, email);


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
    ADD CONSTRAINT gha_comments_pkey PRIMARY KEY (id, event_id);


--
-- Name: gha_commits_files gha_commits_files_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_commits_files
    ADD CONSTRAINT gha_commits_files_pkey PRIMARY KEY (sha, path);


--
-- Name: gha_commits gha_commits_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_commits
    ADD CONSTRAINT gha_commits_pkey PRIMARY KEY (sha, event_id);


--
-- Name: gha_companies gha_companies_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_companies
    ADD CONSTRAINT gha_companies_pkey PRIMARY KEY (name);


--
-- Name: gha_computed gha_computed_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_computed
    ADD CONSTRAINT gha_computed_pkey PRIMARY KEY (metric, dt);


--
-- Name: gha_events_commits_files gha_events_commits_files_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_events_commits_files
    ADD CONSTRAINT gha_events_commits_files_pkey PRIMARY KEY (sha, event_id, path);


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
-- Name: gha_issues_events_labels gha_issues_events_labels_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_issues_events_labels
    ADD CONSTRAINT gha_issues_events_labels_pkey PRIMARY KEY (issue_id, event_id, label_id);


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
-- Name: gha_parsed gha_parsed_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_parsed
    ADD CONSTRAINT gha_parsed_pkey PRIMARY KEY (dt);


--
-- Name: gha_payloads gha_payloads_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_payloads
    ADD CONSTRAINT gha_payloads_pkey PRIMARY KEY (event_id);


--
-- Name: gha_postprocess_scripts gha_postprocess_scripts_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_postprocess_scripts
    ADD CONSTRAINT gha_postprocess_scripts_pkey PRIMARY KEY (ord, path);


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
    ADD CONSTRAINT gha_repos_pkey PRIMARY KEY (id, name);


--
-- Name: gha_skip_commits gha_skip_commits_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_skip_commits
    ADD CONSTRAINT gha_skip_commits_pkey PRIMARY KEY (sha);


--
-- Name: gha_teams gha_teams_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_teams
    ADD CONSTRAINT gha_teams_pkey PRIMARY KEY (id, event_id);


--
-- Name: gha_teams_repositories gha_teams_repositories_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_teams_repositories
    ADD CONSTRAINT gha_teams_repositories_pkey PRIMARY KEY (team_id, event_id, repository_id);


--
-- Name: gha_vars gha_vars_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_vars
    ADD CONSTRAINT gha_vars_pkey PRIMARY KEY (name);


--
-- Name: actors_affiliations_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX actors_affiliations_actor_id_idx ON gha_actors_affiliations USING btree (actor_id);


--
-- Name: actors_affiliations_company_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX actors_affiliations_company_name_idx ON gha_actors_affiliations USING btree (company_name);


--
-- Name: actors_affiliations_dt_from_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX actors_affiliations_dt_from_idx ON gha_actors_affiliations USING btree (dt_from);


--
-- Name: actors_affiliations_dt_to_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX actors_affiliations_dt_to_idx ON gha_actors_affiliations USING btree (dt_to);


--
-- Name: actors_emails_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX actors_emails_actor_id_idx ON gha_actors_emails USING btree (actor_id);


--
-- Name: actors_emails_email_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX actors_emails_email_idx ON gha_actors_emails USING btree (email);


--
-- Name: actors_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX actors_login_idx ON gha_actors USING btree (login);


--
-- Name: actors_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX actors_name_idx ON gha_actors USING btree (name);


--
-- Name: assets_content_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_content_type_idx ON gha_assets USING btree (content_type);


--
-- Name: assets_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_created_at_idx ON gha_assets USING btree (created_at);


--
-- Name: assets_dup_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_dup_actor_id_idx ON gha_assets USING btree (dup_actor_id);


--
-- Name: assets_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_dup_actor_login_idx ON gha_assets USING btree (dup_actor_login);


--
-- Name: assets_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_dup_created_at_idx ON gha_assets USING btree (dup_created_at);


--
-- Name: assets_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_dup_repo_id_idx ON gha_assets USING btree (dup_repo_id);


--
-- Name: assets_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_dup_repo_name_idx ON gha_assets USING btree (dup_repo_name);


--
-- Name: assets_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_dup_type_idx ON gha_assets USING btree (dup_type);


--
-- Name: assets_dup_uploader_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_dup_uploader_login_idx ON gha_assets USING btree (dup_uploader_login);


--
-- Name: assets_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_event_id_idx ON gha_assets USING btree (event_id);


--
-- Name: assets_state_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_state_idx ON gha_assets USING btree (state);


--
-- Name: assets_updated_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_updated_at_idx ON gha_assets USING btree (updated_at);


--
-- Name: assets_uploader_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_uploader_id_idx ON gha_assets USING btree (uploader_id);


--
-- Name: branches_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX branches_dup_created_at_idx ON gha_branches USING btree (dup_created_at);


--
-- Name: branches_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX branches_dup_type_idx ON gha_branches USING btree (dup_type);


--
-- Name: branches_dupn_forkee_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX branches_dupn_forkee_name_idx ON gha_branches USING btree (dupn_forkee_name);


--
-- Name: branches_dupn_user_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX branches_dupn_user_login_idx ON gha_branches USING btree (dupn_user_login);


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
-- Name: comments_dup_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_dup_actor_id_idx ON gha_comments USING btree (dup_actor_id);


--
-- Name: comments_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_dup_actor_login_idx ON gha_comments USING btree (dup_actor_login);


--
-- Name: comments_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_dup_created_at_idx ON gha_comments USING btree (dup_created_at);


--
-- Name: comments_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_dup_repo_id_idx ON gha_comments USING btree (dup_repo_id);


--
-- Name: comments_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_dup_repo_name_idx ON gha_comments USING btree (dup_repo_name);


--
-- Name: comments_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_dup_type_idx ON gha_comments USING btree (dup_type);


--
-- Name: comments_dup_user_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_dup_user_login_idx ON gha_comments USING btree (dup_user_login);


--
-- Name: comments_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_event_id_idx ON gha_comments USING btree (event_id);


--
-- Name: comments_pull_request_review_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_pull_request_review_id_idx ON gha_comments USING btree (pull_request_review_id);


--
-- Name: comments_updated_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_updated_at_idx ON gha_comments USING btree (updated_at);


--
-- Name: comments_user_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_user_id_idx ON gha_comments USING btree (user_id);


--
-- Name: commits_dup_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_dup_actor_id_idx ON gha_commits USING btree (dup_actor_id);


--
-- Name: commits_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_dup_actor_login_idx ON gha_commits USING btree (dup_actor_login);


--
-- Name: commits_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_dup_created_at_idx ON gha_commits USING btree (dup_created_at);


--
-- Name: commits_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_dup_repo_id_idx ON gha_commits USING btree (dup_repo_id);


--
-- Name: commits_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_dup_repo_name_idx ON gha_commits USING btree (dup_repo_name);


--
-- Name: commits_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_dup_type_idx ON gha_commits USING btree (dup_type);


--
-- Name: commits_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_event_id_idx ON gha_commits USING btree (event_id);


--
-- Name: commits_files_dt_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_files_dt_idx ON gha_commits_files USING btree (dt);


--
-- Name: commits_files_path_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_files_path_idx ON gha_commits_files USING btree (path);


--
-- Name: commits_files_sha_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_files_sha_idx ON gha_commits_files USING btree (sha);


--
-- Name: commits_files_size_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_files_size_idx ON gha_commits_files USING btree (size);


--
-- Name: computed_dt_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX computed_dt_idx ON gha_computed USING btree (dt);


--
-- Name: computed_metric_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX computed_metric_idx ON gha_computed USING btree (metric);


--
-- Name: events_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_actor_id_idx ON gha_events USING btree (actor_id);


--
-- Name: events_commits_files_dt_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_commits_files_dt_idx ON gha_events_commits_files USING btree (dt);


--
-- Name: events_commits_files_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_commits_files_dup_created_at_idx ON gha_events_commits_files USING btree (dup_created_at);


--
-- Name: events_commits_files_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_commits_files_dup_repo_id_idx ON gha_events_commits_files USING btree (dup_repo_id);


--
-- Name: events_commits_files_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_commits_files_dup_repo_name_idx ON gha_events_commits_files USING btree (dup_repo_name);


--
-- Name: events_commits_files_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_commits_files_dup_type_idx ON gha_events_commits_files USING btree (dup_type);


--
-- Name: events_commits_files_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_commits_files_event_id_idx ON gha_events_commits_files USING btree (event_id);


--
-- Name: events_commits_files_path_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_commits_files_path_idx ON gha_events_commits_files USING btree (path);


--
-- Name: events_commits_files_repo_group_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_commits_files_repo_group_idx ON gha_events_commits_files USING btree (repo_group);


--
-- Name: events_commits_files_sha_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_commits_files_sha_idx ON gha_events_commits_files USING btree (sha);


--
-- Name: events_commits_files_size_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_commits_files_size_idx ON gha_events_commits_files USING btree (size);


--
-- Name: events_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_created_at_idx ON gha_events USING btree (created_at);


--
-- Name: events_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_dup_actor_login_idx ON gha_events USING btree (dup_actor_login);


--
-- Name: events_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_dup_repo_name_idx ON gha_events USING btree (dup_repo_name);


--
-- Name: events_forkee_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_forkee_id_idx ON gha_events USING btree (forkee_id);


--
-- Name: events_org_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_org_id_idx ON gha_events USING btree (org_id);


--
-- Name: events_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_repo_id_idx ON gha_events USING btree (repo_id);


--
-- Name: events_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_type_idx ON gha_events USING btree (type);


--
-- Name: forkees_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_created_at_idx ON gha_forkees USING btree (created_at);


--
-- Name: forkees_dup_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_dup_actor_id_idx ON gha_forkees USING btree (dup_actor_id);


--
-- Name: forkees_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_dup_actor_login_idx ON gha_forkees USING btree (dup_actor_login);


--
-- Name: forkees_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_dup_created_at_idx ON gha_forkees USING btree (dup_created_at);


--
-- Name: forkees_dup_owner_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_dup_owner_login_idx ON gha_forkees USING btree (dup_owner_login);


--
-- Name: forkees_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_dup_repo_id_idx ON gha_forkees USING btree (dup_repo_id);


--
-- Name: forkees_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_dup_repo_name_idx ON gha_forkees USING btree (dup_repo_name);


--
-- Name: forkees_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_dup_type_idx ON gha_forkees USING btree (dup_type);


--
-- Name: forkees_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_event_id_idx ON gha_forkees USING btree (event_id);


--
-- Name: forkees_language_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_language_idx ON gha_forkees USING btree (language);


--
-- Name: forkees_organization_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_organization_idx ON gha_forkees USING btree (organization);


--
-- Name: forkees_owner_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_owner_id_idx ON gha_forkees USING btree (owner_id);


--
-- Name: forkees_updated_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_updated_at_idx ON gha_forkees USING btree (updated_at);


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
-- Name: issues_dup_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_dup_actor_id_idx ON gha_issues USING btree (dup_actor_id);


--
-- Name: issues_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_dup_actor_login_idx ON gha_issues USING btree (dup_actor_login);


--
-- Name: issues_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_dup_created_at_idx ON gha_issues USING btree (dup_created_at);


--
-- Name: issues_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_dup_repo_id_idx ON gha_issues USING btree (dup_repo_id);


--
-- Name: issues_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_dup_repo_name_idx ON gha_issues USING btree (dup_repo_name);


--
-- Name: issues_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_dup_type_idx ON gha_issues USING btree (dup_type);


--
-- Name: issues_dup_user_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_dup_user_login_idx ON gha_issues USING btree (dup_user_login);


--
-- Name: issues_dupn_assignee_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_dupn_assignee_login_idx ON gha_issues USING btree (dupn_assignee_login);


--
-- Name: issues_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_event_id_idx ON gha_issues USING btree (event_id);


--
-- Name: issues_events_labels_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_events_labels_actor_id_idx ON gha_issues_events_labels USING btree (actor_id);


--
-- Name: issues_events_labels_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_events_labels_actor_login_idx ON gha_issues_events_labels USING btree (actor_login);


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
-- Name: issues_events_labels_issue_number_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_events_labels_issue_number_idx ON gha_issues_events_labels USING btree (issue_number);


--
-- Name: issues_events_labels_label_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_events_labels_label_id_idx ON gha_issues_events_labels USING btree (label_id);


--
-- Name: issues_events_labels_label_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_events_labels_label_name_idx ON gha_issues_events_labels USING btree (label_name);


--
-- Name: issues_events_labels_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_events_labels_repo_id_idx ON gha_issues_events_labels USING btree (repo_id);


--
-- Name: issues_events_labels_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_events_labels_repo_name_idx ON gha_issues_events_labels USING btree (repo_name);


--
-- Name: issues_events_labels_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_events_labels_type_idx ON gha_issues_events_labels USING btree (type);


--
-- Name: issues_is_pull_request_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_is_pull_request_idx ON gha_issues USING btree (is_pull_request);


--
-- Name: issues_labels_dup_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_labels_dup_actor_id_idx ON gha_issues_labels USING btree (dup_actor_id);


--
-- Name: issues_labels_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_labels_dup_actor_login_idx ON gha_issues_labels USING btree (dup_actor_login);


--
-- Name: issues_labels_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_labels_dup_created_at_idx ON gha_issues_labels USING btree (dup_created_at);


--
-- Name: issues_labels_dup_issue_number_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_labels_dup_issue_number_idx ON gha_issues_labels USING btree (dup_issue_number);


--
-- Name: issues_labels_dup_label_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_labels_dup_label_name_idx ON gha_issues_labels USING btree (dup_label_name);


--
-- Name: issues_labels_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_labels_dup_repo_id_idx ON gha_issues_labels USING btree (dup_repo_id);


--
-- Name: issues_labels_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_labels_dup_repo_name_idx ON gha_issues_labels USING btree (dup_repo_name);


--
-- Name: issues_labels_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_labels_dup_type_idx ON gha_issues_labels USING btree (dup_type);


--
-- Name: issues_milestone_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_milestone_id_idx ON gha_issues USING btree (milestone_id);


--
-- Name: issues_pull_requests_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_pull_requests_created_at_idx ON gha_issues_pull_requests USING btree (created_at);


--
-- Name: issues_pull_requests_issue_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_pull_requests_issue_id_idx ON gha_issues_pull_requests USING btree (issue_id);


--
-- Name: issues_pull_requests_number_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_pull_requests_number_idx ON gha_issues_pull_requests USING btree (number);


--
-- Name: issues_pull_requests_pull_request_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_pull_requests_pull_request_id_idx ON gha_issues_pull_requests USING btree (pull_request_id);


--
-- Name: issues_pull_requests_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_pull_requests_repo_id_idx ON gha_issues_pull_requests USING btree (repo_id);


--
-- Name: issues_pull_requests_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_pull_requests_repo_name_idx ON gha_issues_pull_requests USING btree (repo_name);


--
-- Name: issues_state_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_state_idx ON gha_issues USING btree (state);


--
-- Name: issues_updated_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_updated_at_idx ON gha_issues USING btree (updated_at);


--
-- Name: issues_user_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_user_id_idx ON gha_issues USING btree (user_id);


--
-- Name: labels_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX labels_name_idx ON gha_labels USING btree (name);


--
-- Name: logs_dt_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX logs_dt_idx ON gha_logs USING btree (dt);


--
-- Name: logs_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX logs_id_idx ON gha_logs USING btree (id);


--
-- Name: logs_prog_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX logs_prog_idx ON gha_logs USING btree (prog);


--
-- Name: logs_proj_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX logs_proj_idx ON gha_logs USING btree (proj);


--
-- Name: logs_run_dt_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX logs_run_dt_idx ON gha_logs USING btree (run_dt);


--
-- Name: milestones_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_created_at_idx ON gha_milestones USING btree (created_at);


--
-- Name: milestones_creator_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_creator_id_idx ON gha_milestones USING btree (creator_id);


--
-- Name: milestones_dup_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_dup_actor_id_idx ON gha_milestones USING btree (dup_actor_id);


--
-- Name: milestones_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_dup_actor_login_idx ON gha_milestones USING btree (dup_actor_login);


--
-- Name: milestones_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_dup_created_at_idx ON gha_milestones USING btree (dup_created_at);


--
-- Name: milestones_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_dup_repo_id_idx ON gha_milestones USING btree (dup_repo_id);


--
-- Name: milestones_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_dup_repo_name_idx ON gha_milestones USING btree (dup_repo_name);


--
-- Name: milestones_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_dup_type_idx ON gha_milestones USING btree (dup_type);


--
-- Name: milestones_dupn_creator_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_dupn_creator_login_idx ON gha_milestones USING btree (dupn_creator_login);


--
-- Name: milestones_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_event_id_idx ON gha_milestones USING btree (event_id);


--
-- Name: milestones_state_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_state_idx ON gha_milestones USING btree (state);


--
-- Name: milestones_updated_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_updated_at_idx ON gha_milestones USING btree (updated_at);


--
-- Name: orgs_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX orgs_login_idx ON gha_orgs USING btree (login);


--
-- Name: pages_action_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pages_action_idx ON gha_pages USING btree (action);


--
-- Name: pages_dup_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pages_dup_actor_id_idx ON gha_pages USING btree (dup_actor_id);


--
-- Name: pages_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pages_dup_actor_login_idx ON gha_pages USING btree (dup_actor_login);


--
-- Name: pages_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pages_dup_created_at_idx ON gha_pages USING btree (dup_created_at);


--
-- Name: pages_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pages_dup_repo_id_idx ON gha_pages USING btree (dup_repo_id);


--
-- Name: pages_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pages_dup_repo_name_idx ON gha_pages USING btree (dup_repo_name);


--
-- Name: pages_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pages_dup_type_idx ON gha_pages USING btree (dup_type);


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
-- Name: payloads_commit_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_commit_idx ON gha_payloads USING btree (commit);


--
-- Name: payloads_dup_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_dup_actor_id_idx ON gha_payloads USING btree (dup_actor_id);


--
-- Name: payloads_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_dup_actor_login_idx ON gha_payloads USING btree (dup_actor_login);


--
-- Name: payloads_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_dup_created_at_idx ON gha_payloads USING btree (dup_created_at);


--
-- Name: payloads_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_dup_repo_id_idx ON gha_payloads USING btree (dup_repo_id);


--
-- Name: payloads_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_dup_repo_name_idx ON gha_payloads USING btree (dup_repo_name);


--
-- Name: payloads_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_dup_type_idx ON gha_payloads USING btree (dup_type);


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
-- Name: payloads_pull_request_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_pull_request_id_idx ON gha_payloads USING btree (issue_id);


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
-- Name: pull_requests_dup_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_dup_actor_id_idx ON gha_pull_requests USING btree (dup_actor_id);


--
-- Name: pull_requests_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_dup_actor_login_idx ON gha_pull_requests USING btree (dup_actor_login);


--
-- Name: pull_requests_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_dup_created_at_idx ON gha_pull_requests USING btree (dup_created_at);


--
-- Name: pull_requests_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_dup_repo_id_idx ON gha_pull_requests USING btree (dup_repo_id);


--
-- Name: pull_requests_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_dup_repo_name_idx ON gha_pull_requests USING btree (dup_repo_name);


--
-- Name: pull_requests_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_dup_type_idx ON gha_pull_requests USING btree (dup_type);


--
-- Name: pull_requests_dup_user_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_dup_user_login_idx ON gha_pull_requests USING btree (dup_user_login);


--
-- Name: pull_requests_dupn_assignee_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_dupn_assignee_login_idx ON gha_pull_requests USING btree (dupn_assignee_login);


--
-- Name: pull_requests_dupn_merged_by_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_dupn_merged_by_login_idx ON gha_pull_requests USING btree (dupn_merged_by_login);


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
-- Name: pull_requests_updated_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_updated_at_idx ON gha_pull_requests USING btree (updated_at);


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
-- Name: releases_dup_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX releases_dup_actor_id_idx ON gha_releases USING btree (dup_actor_id);


--
-- Name: releases_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX releases_dup_actor_login_idx ON gha_releases USING btree (dup_actor_login);


--
-- Name: releases_dup_author_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX releases_dup_author_login_idx ON gha_releases USING btree (dup_author_login);


--
-- Name: releases_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX releases_dup_created_at_idx ON gha_releases USING btree (dup_created_at);


--
-- Name: releases_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX releases_dup_repo_id_idx ON gha_releases USING btree (dup_repo_id);


--
-- Name: releases_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX releases_dup_repo_name_idx ON gha_releases USING btree (dup_repo_name);


--
-- Name: releases_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX releases_dup_type_idx ON gha_releases USING btree (dup_type);


--
-- Name: releases_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX releases_event_id_idx ON gha_releases USING btree (event_id);


--
-- Name: repos_alias_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX repos_alias_idx ON gha_repos USING btree (alias);


--
-- Name: repos_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX repos_name_idx ON gha_repos USING btree (name);


--
-- Name: repos_org_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX repos_org_id_idx ON gha_repos USING btree (org_id);


--
-- Name: repos_org_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX repos_org_login_idx ON gha_repos USING btree (org_login);


--
-- Name: repos_repo_group_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX repos_repo_group_idx ON gha_repos USING btree (repo_group);


--
-- Name: skip_commits_sha_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX skip_commits_sha_idx ON gha_skip_commits USING btree (sha);


--
-- Name: teams_dup_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX teams_dup_actor_id_idx ON gha_teams USING btree (dup_actor_id);


--
-- Name: teams_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX teams_dup_actor_login_idx ON gha_teams USING btree (dup_actor_login);


--
-- Name: teams_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX teams_dup_created_at_idx ON gha_teams USING btree (dup_created_at);


--
-- Name: teams_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX teams_dup_repo_id_idx ON gha_teams USING btree (dup_repo_id);


--
-- Name: teams_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX teams_dup_repo_name_idx ON gha_teams USING btree (dup_repo_name);


--
-- Name: teams_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX teams_dup_type_idx ON gha_teams USING btree (dup_type);


--
-- Name: teams_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX teams_event_id_idx ON gha_teams USING btree (event_id);


--
-- Name: teams_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX teams_name_idx ON gha_teams USING btree (name);


--
-- Name: teams_permission_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX teams_permission_idx ON gha_teams USING btree (permission);


--
-- Name: teams_slug_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX teams_slug_idx ON gha_teams USING btree (slug);


--
-- Name: texts_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX texts_actor_id_idx ON gha_texts USING btree (actor_id);


--
-- Name: texts_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX texts_actor_login_idx ON gha_texts USING btree (actor_login);


--
-- Name: texts_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX texts_created_at_idx ON gha_texts USING btree (created_at);


--
-- Name: texts_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX texts_event_id_idx ON gha_texts USING btree (event_id);


--
-- Name: texts_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX texts_repo_id_idx ON gha_texts USING btree (repo_id);


--
-- Name: texts_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX texts_repo_name_idx ON gha_texts USING btree (repo_name);


--
-- Name: texts_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX texts_type_idx ON gha_texts USING btree (type);


--
-- Name: vars_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX vars_name_idx ON gha_vars USING btree (name);


--
-- Name: gha_actors; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_actors TO ro_user;
GRANT SELECT ON TABLE gha_actors TO devstats_team;


--
-- Name: gha_actors_affiliations; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_actors_affiliations TO ro_user;
GRANT SELECT ON TABLE gha_actors_affiliations TO devstats_team;


--
-- Name: gha_actors_emails; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_actors_emails TO ro_user;
GRANT SELECT ON TABLE gha_actors_emails TO devstats_team;


--
-- Name: gha_assets; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_assets TO ro_user;
GRANT SELECT ON TABLE gha_assets TO devstats_team;


--
-- Name: gha_branches; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_branches TO ro_user;
GRANT SELECT ON TABLE gha_branches TO devstats_team;


--
-- Name: gha_comments; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_comments TO ro_user;
GRANT SELECT ON TABLE gha_comments TO devstats_team;


--
-- Name: gha_commits; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_commits TO ro_user;
GRANT SELECT ON TABLE gha_commits TO devstats_team;


--
-- Name: gha_commits_files; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_commits_files TO ro_user;
GRANT SELECT ON TABLE gha_commits_files TO devstats_team;


--
-- Name: gha_companies; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_companies TO ro_user;
GRANT SELECT ON TABLE gha_companies TO devstats_team;


--
-- Name: gha_events; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_events TO ro_user;
GRANT SELECT ON TABLE gha_events TO devstats_team;


--
-- Name: gha_events_commits_files; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_events_commits_files TO ro_user;
GRANT SELECT ON TABLE gha_events_commits_files TO devstats_team;


--
-- Name: gha_forkees; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_forkees TO ro_user;
GRANT SELECT ON TABLE gha_forkees TO devstats_team;


--
-- Name: gha_issues; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_issues TO ro_user;
GRANT SELECT ON TABLE gha_issues TO devstats_team;


--
-- Name: gha_issues_assignees; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_issues_assignees TO ro_user;
GRANT SELECT ON TABLE gha_issues_assignees TO devstats_team;


--
-- Name: gha_issues_events_labels; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_issues_events_labels TO ro_user;
GRANT SELECT ON TABLE gha_issues_events_labels TO devstats_team;


--
-- Name: gha_issues_labels; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_issues_labels TO ro_user;
GRANT SELECT ON TABLE gha_issues_labels TO devstats_team;


--
-- Name: gha_issues_pull_requests; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_issues_pull_requests TO ro_user;
GRANT SELECT ON TABLE gha_issues_pull_requests TO devstats_team;


--
-- Name: gha_labels; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_labels TO ro_user;
GRANT SELECT ON TABLE gha_labels TO devstats_team;


--
-- Name: gha_logs; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_logs TO ro_user;
GRANT SELECT ON TABLE gha_logs TO devstats_team;


--
-- Name: gha_milestones; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_milestones TO ro_user;
GRANT SELECT ON TABLE gha_milestones TO devstats_team;


--
-- Name: gha_orgs; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_orgs TO ro_user;
GRANT SELECT ON TABLE gha_orgs TO devstats_team;


--
-- Name: gha_pages; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_pages TO ro_user;
GRANT SELECT ON TABLE gha_pages TO devstats_team;


--
-- Name: gha_payloads; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_payloads TO ro_user;
GRANT SELECT ON TABLE gha_payloads TO devstats_team;


--
-- Name: gha_postprocess_scripts; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_postprocess_scripts TO ro_user;
GRANT SELECT ON TABLE gha_postprocess_scripts TO devstats_team;


--
-- Name: gha_pull_requests; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_pull_requests TO ro_user;
GRANT SELECT ON TABLE gha_pull_requests TO devstats_team;


--
-- Name: gha_pull_requests_assignees; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_pull_requests_assignees TO ro_user;
GRANT SELECT ON TABLE gha_pull_requests_assignees TO devstats_team;


--
-- Name: gha_pull_requests_requested_reviewers; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_pull_requests_requested_reviewers TO ro_user;
GRANT SELECT ON TABLE gha_pull_requests_requested_reviewers TO devstats_team;


--
-- Name: gha_releases; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_releases TO ro_user;
GRANT SELECT ON TABLE gha_releases TO devstats_team;


--
-- Name: gha_releases_assets; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_releases_assets TO ro_user;
GRANT SELECT ON TABLE gha_releases_assets TO devstats_team;


--
-- Name: gha_repos; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_repos TO ro_user;
GRANT SELECT ON TABLE gha_repos TO devstats_team;


--
-- Name: gha_skip_commits; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_skip_commits TO ro_user;
GRANT SELECT ON TABLE gha_skip_commits TO devstats_team;


--
-- Name: gha_teams; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_teams TO ro_user;
GRANT SELECT ON TABLE gha_teams TO devstats_team;


--
-- Name: gha_teams_repositories; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_teams_repositories TO ro_user;
GRANT SELECT ON TABLE gha_teams_repositories TO devstats_team;


--
-- Name: gha_texts; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_texts TO ro_user;
GRANT SELECT ON TABLE gha_texts TO devstats_team;


--
-- Name: gha_vars; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE gha_vars TO ro_user;
GRANT SELECT ON TABLE gha_vars TO devstats_team;


--
-- PostgreSQL database dump complete
--

