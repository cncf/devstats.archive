--
-- PostgreSQL database dump
--

-- Dumped from database version 10.5 (Ubuntu 10.5-0ubuntu0.18.04)
-- Dumped by pg_dump version 10.5 (Ubuntu 10.5-0ubuntu0.18.04)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: current_state; Type: SCHEMA; Schema: -; Owner: devstats_team
--

CREATE SCHEMA current_state;


ALTER SCHEMA current_state OWNER TO devstats_team;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: label_prefix(text); Type: FUNCTION; Schema: current_state; Owner: devstats_team
--

CREATE FUNCTION current_state.label_prefix(some_label text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
SELECT CASE WHEN $1 LIKE '%_/_%' 
  THEN split_part($1, '/', 1)
ELSE
  'general'
END;
$_$;


ALTER FUNCTION current_state.label_prefix(some_label text) OWNER TO devstats_team;

--
-- Name: label_suffix(text); Type: FUNCTION; Schema: current_state; Owner: devstats_team
--

CREATE FUNCTION current_state.label_suffix(some_label text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
SELECT CASE WHEN $1 LIKE '%_/_%'
  THEN substring($1 FROM '/(.*)') 
ELSE
  $1
END;
$_$;


ALTER FUNCTION current_state.label_suffix(some_label text) OWNER TO devstats_team;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: gha_issues_labels; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_issues_labels (
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


ALTER TABLE public.gha_issues_labels OWNER TO gha_admin;

--
-- Name: issue_labels; Type: MATERIALIZED VIEW; Schema: current_state; Owner: devstats_team
--

CREATE MATERIALIZED VIEW current_state.issue_labels AS
 WITH label_fields AS (
         SELECT gha_issues_labels.issue_id,
            gha_issues_labels.label_id,
            gha_issues_labels.event_id,
            gha_issues_labels.dup_label_name
           FROM public.gha_issues_labels
        ), event_rank AS (
         SELECT gha_issues_labels.issue_id,
            gha_issues_labels.event_id,
            row_number() OVER (PARTITION BY gha_issues_labels.issue_id ORDER BY gha_issues_labels.event_id DESC) AS rank
           FROM public.gha_issues_labels
          GROUP BY gha_issues_labels.issue_id, gha_issues_labels.event_id
        )
 SELECT label_fields.issue_id,
    label_fields.label_id,
    label_fields.dup_label_name AS full_label,
    current_state.label_prefix((label_fields.dup_label_name)::text) AS prefix,
    current_state.label_suffix((label_fields.dup_label_name)::text) AS label
   FROM (label_fields
     JOIN event_rank ON (((label_fields.issue_id = event_rank.issue_id) AND (label_fields.event_id = event_rank.event_id) AND (event_rank.rank = 1))))
  ORDER BY label_fields.issue_id, (current_state.label_prefix((label_fields.dup_label_name)::text)), (current_state.label_suffix((label_fields.dup_label_name)::text))
  WITH NO DATA;


ALTER TABLE current_state.issue_labels OWNER TO devstats_team;

--
-- Name: gha_milestones; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_milestones (
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


ALTER TABLE public.gha_milestones OWNER TO gha_admin;

--
-- Name: milestones; Type: MATERIALIZED VIEW; Schema: current_state; Owner: devstats_team
--

CREATE MATERIALIZED VIEW current_state.milestones AS
 WITH milestone_latest AS (
         SELECT gha_milestones.id,
            gha_milestones.title AS milestone,
            gha_milestones.state,
            gha_milestones.created_at,
            gha_milestones.updated_at,
            gha_milestones.closed_at,
            gha_milestones.event_id,
            gha_milestones.dup_repo_id AS repo_id,
            gha_milestones.dup_repo_name AS repo_name,
            row_number() OVER (PARTITION BY gha_milestones.id ORDER BY gha_milestones.updated_at DESC, gha_milestones.event_id DESC) AS rank
           FROM public.gha_milestones
        )
 SELECT milestone_latest.id,
    milestone_latest.milestone,
    milestone_latest.state,
    milestone_latest.created_at,
    milestone_latest.updated_at,
    milestone_latest.closed_at,
    milestone_latest.repo_id,
    milestone_latest.repo_name
   FROM milestone_latest
  WHERE (milestone_latest.rank = 1)
  WITH NO DATA;


ALTER TABLE current_state.milestones OWNER TO devstats_team;

--
-- Name: gha_issues; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_issues (
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


ALTER TABLE public.gha_issues OWNER TO gha_admin;

--
-- Name: issues; Type: MATERIALIZED VIEW; Schema: current_state; Owner: devstats_team
--

CREATE MATERIALIZED VIEW current_state.issues AS
 WITH issue_latest AS (
         SELECT issues.id,
            issues.dup_repo_id AS repo_id,
            issues.dup_repo_name AS repo_name,
            issues.number,
            issues.is_pull_request,
            issues.milestone_id,
            milestones.milestone,
            issues.state,
            issues.title,
            issues.user_id AS creator_id,
            issues.assignee_id,
            issues.dup_created_at AS created_at,
            issues.updated_at,
            issues.closed_at,
            issues.body,
            issues.comments,
            row_number() OVER (PARTITION BY issues.id ORDER BY issues.updated_at DESC, issues.event_id DESC) AS rank
           FROM (public.gha_issues issues
             JOIN current_state.milestones ON ((issues.milestone_id = milestones.id)))
        )
 SELECT issue_latest.id,
    issue_latest.repo_id,
    issue_latest.repo_name,
    issue_latest.number,
    issue_latest.is_pull_request,
    issue_latest.milestone_id,
    issue_latest.milestone,
    issue_latest.state,
    issue_latest.title,
    issue_latest.creator_id,
    issue_latest.assignee_id,
    issue_latest.created_at,
    issue_latest.updated_at,
    issue_latest.closed_at,
    issue_latest.body,
    issue_latest.comments
   FROM issue_latest
  WHERE (issue_latest.rank = 1)
  ORDER BY issue_latest.repo_name, issue_latest.number
  WITH NO DATA;


ALTER TABLE current_state.issues OWNER TO devstats_team;

--
-- Name: priorities; Type: TABLE; Schema: current_state; Owner: devstats_team
--

CREATE TABLE current_state.priorities (
    priority text,
    label_sort integer
);


ALTER TABLE current_state.priorities OWNER TO devstats_team;

--
-- Name: issues_by_priority; Type: VIEW; Schema: current_state; Owner: devstats_team
--

CREATE VIEW current_state.issues_by_priority AS
 WITH prior_groups AS (
         SELECT COALESCE(priorities.priority, 'no priority'::text) AS priority,
            COALESCE(priorities.label_sort, 99) AS label_sort,
            count(*) FILTER (WHERE ((issues.state)::text = 'open'::text)) AS open_issues,
            count(*) FILTER (WHERE ((issues.state)::text = 'closed'::text)) AS closed_issues
           FROM ((current_state.issues
             LEFT JOIN current_state.issue_labels ON (((issues.id = issue_labels.issue_id) AND (issue_labels.prefix = 'priority'::text))))
             LEFT JOIN current_state.priorities ON ((issue_labels.label = priorities.priority)))
          WHERE (((issues.milestone)::text = 'v1.11'::text) AND ((issues.repo_name)::text = 'kubernetes/kubernetes'::text) AND (NOT issues.is_pull_request))
          GROUP BY COALESCE(priorities.priority, 'no priority'::text), COALESCE(priorities.label_sort, 99)
        UNION ALL
         SELECT 'TOTAL'::text AS text,
            999,
            count(*) FILTER (WHERE ((issues.state)::text = 'open'::text)) AS open_issues,
            count(*) FILTER (WHERE ((issues.state)::text = 'closed'::text)) AS closed_issues
           FROM current_state.issues
          WHERE (((issues.milestone)::text = 'v1.11'::text) AND ((issues.repo_name)::text = 'kubernetes/kubernetes'::text) AND (NOT issues.is_pull_request))
        )
 SELECT prior_groups.priority,
    prior_groups.open_issues,
    prior_groups.closed_issues
   FROM prior_groups
  ORDER BY prior_groups.label_sort;


ALTER TABLE current_state.issues_by_priority OWNER TO devstats_team;

--
-- Name: gha_pull_requests; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_pull_requests (
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


ALTER TABLE public.gha_pull_requests OWNER TO gha_admin;

--
-- Name: prs; Type: MATERIALIZED VIEW; Schema: current_state; Owner: devstats_team
--

CREATE MATERIALIZED VIEW current_state.prs AS
 WITH pr_latest AS (
         SELECT prs.id,
            prs.dup_repo_id AS repo_id,
            prs.dup_repo_name AS repo_name,
            prs.number,
            prs.milestone_id,
            milestones.milestone,
            prs.state,
            prs.title,
            prs.user_id AS creator_id,
            prs.assignee_id,
            prs.dup_created_at AS created_at,
            prs.updated_at,
            prs.closed_at,
            prs.merged_at,
            prs.body,
            prs.comments,
            row_number() OVER (PARTITION BY prs.id ORDER BY prs.updated_at DESC, prs.event_id DESC) AS rank
           FROM (public.gha_pull_requests prs
             LEFT JOIN current_state.milestones ON ((prs.milestone_id = milestones.id)))
        )
 SELECT pr_latest.id,
    pr_latest.repo_id,
    pr_latest.repo_name,
    pr_latest.number,
    pr_latest.milestone_id,
    pr_latest.milestone,
    pr_latest.state,
    pr_latest.title,
    pr_latest.creator_id,
    pr_latest.assignee_id,
    pr_latest.created_at,
    pr_latest.updated_at,
    pr_latest.closed_at,
    pr_latest.merged_at,
    pr_latest.body,
    pr_latest.comments
   FROM pr_latest
  WHERE (pr_latest.rank = 1)
  ORDER BY pr_latest.repo_name, pr_latest.number
  WITH NO DATA;


ALTER TABLE current_state.prs OWNER TO devstats_team;

--
-- Name: gha_actors; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_actors (
    id bigint NOT NULL,
    login character varying(120) NOT NULL,
    name character varying(120)
);


ALTER TABLE public.gha_actors OWNER TO gha_admin;

--
-- Name: gha_actors_affiliations; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_actors_affiliations (
    actor_id bigint NOT NULL,
    company_name character varying(160) NOT NULL,
    dt_from timestamp without time zone NOT NULL,
    dt_to timestamp without time zone NOT NULL
);


ALTER TABLE public.gha_actors_affiliations OWNER TO gha_admin;

--
-- Name: gha_actors_emails; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_actors_emails (
    actor_id bigint NOT NULL,
    email character varying(120) NOT NULL
);


ALTER TABLE public.gha_actors_emails OWNER TO gha_admin;

--
-- Name: gha_assets; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_assets (
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


ALTER TABLE public.gha_assets OWNER TO gha_admin;

--
-- Name: gha_branches; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_branches (
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


ALTER TABLE public.gha_branches OWNER TO gha_admin;

--
-- Name: gha_comments; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_comments (
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


ALTER TABLE public.gha_comments OWNER TO gha_admin;

--
-- Name: gha_commits; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_commits (
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
    dup_created_at timestamp without time zone NOT NULL,
    encrypted_email character varying(160) NOT NULL
);


ALTER TABLE public.gha_commits OWNER TO gha_admin;

--
-- Name: gha_commits_files; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_commits_files (
    sha character varying(40) NOT NULL,
    path text NOT NULL,
    size bigint NOT NULL,
    dt timestamp without time zone NOT NULL
);


ALTER TABLE public.gha_commits_files OWNER TO gha_admin;

--
-- Name: gha_companies; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_companies (
    name character varying(160) NOT NULL
);


ALTER TABLE public.gha_companies OWNER TO gha_admin;

--
-- Name: gha_computed; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_computed (
    metric text NOT NULL,
    dt timestamp without time zone NOT NULL
);


ALTER TABLE public.gha_computed OWNER TO gha_admin;

--
-- Name: gha_events; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_events (
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


ALTER TABLE public.gha_events OWNER TO gha_admin;

--
-- Name: gha_events_commits_files; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_events_commits_files (
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


ALTER TABLE public.gha_events_commits_files OWNER TO gha_admin;

--
-- Name: gha_forkees; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_forkees (
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


ALTER TABLE public.gha_forkees OWNER TO gha_admin;

--
-- Name: gha_issues_assignees; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_issues_assignees (
    issue_id bigint NOT NULL,
    event_id bigint NOT NULL,
    assignee_id bigint NOT NULL
);


ALTER TABLE public.gha_issues_assignees OWNER TO gha_admin;

--
-- Name: gha_issues_events_labels; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_issues_events_labels (
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


ALTER TABLE public.gha_issues_events_labels OWNER TO gha_admin;

--
-- Name: gha_issues_pull_requests; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_issues_pull_requests (
    issue_id bigint NOT NULL,
    pull_request_id bigint NOT NULL,
    number integer NOT NULL,
    repo_id bigint NOT NULL,
    repo_name character varying(160) NOT NULL,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.gha_issues_pull_requests OWNER TO gha_admin;

--
-- Name: gha_labels; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_labels (
    id bigint NOT NULL,
    name character varying(160) NOT NULL,
    color character varying(8) NOT NULL,
    is_default boolean
);


ALTER TABLE public.gha_labels OWNER TO gha_admin;

--
-- Name: gha_logs; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_logs (
    id integer NOT NULL,
    dt timestamp without time zone DEFAULT now(),
    prog character varying(32) NOT NULL,
    proj character varying(32) NOT NULL,
    run_dt timestamp without time zone NOT NULL,
    msg text
);


ALTER TABLE public.gha_logs OWNER TO gha_admin;

--
-- Name: gha_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: gha_admin
--

CREATE SEQUENCE public.gha_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.gha_logs_id_seq OWNER TO gha_admin;

--
-- Name: gha_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gha_admin
--

ALTER SEQUENCE public.gha_logs_id_seq OWNED BY public.gha_logs.id;


--
-- Name: gha_orgs; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_orgs (
    id bigint NOT NULL,
    login character varying(100) NOT NULL
);


ALTER TABLE public.gha_orgs OWNER TO gha_admin;

--
-- Name: gha_pages; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_pages (
    sha character varying(40) NOT NULL,
    event_id bigint NOT NULL,
    action character varying(40) NOT NULL,
    title character varying(300) NOT NULL,
    dup_actor_id bigint NOT NULL,
    dup_actor_login character varying(120) NOT NULL,
    dup_repo_id bigint NOT NULL,
    dup_repo_name character varying(160) NOT NULL,
    dup_type character varying(40) NOT NULL,
    dup_created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.gha_pages OWNER TO gha_admin;

--
-- Name: gha_parsed; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_parsed (
    dt timestamp without time zone NOT NULL
);


ALTER TABLE public.gha_parsed OWNER TO gha_admin;

--
-- Name: gha_payloads; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_payloads (
    event_id bigint NOT NULL,
    push_id bigint,
    size integer,
    ref character varying(200),
    head character varying(40),
    befor character varying(40),
    action character varying(40),
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


ALTER TABLE public.gha_payloads OWNER TO gha_admin;

--
-- Name: gha_postprocess_scripts; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_postprocess_scripts (
    ord integer NOT NULL,
    path text NOT NULL
);


ALTER TABLE public.gha_postprocess_scripts OWNER TO gha_admin;

--
-- Name: gha_pull_requests_assignees; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_pull_requests_assignees (
    pull_request_id bigint NOT NULL,
    event_id bigint NOT NULL,
    assignee_id bigint NOT NULL
);


ALTER TABLE public.gha_pull_requests_assignees OWNER TO gha_admin;

--
-- Name: gha_pull_requests_requested_reviewers; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_pull_requests_requested_reviewers (
    pull_request_id bigint NOT NULL,
    event_id bigint NOT NULL,
    requested_reviewer_id bigint NOT NULL
);


ALTER TABLE public.gha_pull_requests_requested_reviewers OWNER TO gha_admin;

--
-- Name: gha_releases; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_releases (
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


ALTER TABLE public.gha_releases OWNER TO gha_admin;

--
-- Name: gha_releases_assets; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_releases_assets (
    release_id bigint NOT NULL,
    event_id bigint NOT NULL,
    asset_id bigint NOT NULL
);


ALTER TABLE public.gha_releases_assets OWNER TO gha_admin;

--
-- Name: gha_repos; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_repos (
    id bigint NOT NULL,
    name character varying(160) NOT NULL,
    org_id bigint,
    org_login character varying(100),
    repo_group character varying(80),
    alias character varying(160)
);


ALTER TABLE public.gha_repos OWNER TO gha_admin;

--
-- Name: gha_skip_commits; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_skip_commits (
    sha character varying(40) NOT NULL,
    dt timestamp without time zone NOT NULL
);


ALTER TABLE public.gha_skip_commits OWNER TO gha_admin;

--
-- Name: gha_teams; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_teams (
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


ALTER TABLE public.gha_teams OWNER TO gha_admin;

--
-- Name: gha_teams_repositories; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_teams_repositories (
    team_id bigint NOT NULL,
    event_id bigint NOT NULL,
    repository_id bigint NOT NULL
);


ALTER TABLE public.gha_teams_repositories OWNER TO gha_admin;

--
-- Name: gha_texts; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_texts (
    event_id bigint,
    body text,
    created_at timestamp without time zone NOT NULL,
    actor_id bigint NOT NULL,
    actor_login character varying(120) NOT NULL,
    repo_id bigint NOT NULL,
    repo_name character varying(160) NOT NULL,
    type character varying(40) NOT NULL
);


ALTER TABLE public.gha_texts OWNER TO gha_admin;

--
-- Name: gha_vars; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.gha_vars (
    name character varying(100) NOT NULL,
    value_i bigint,
    value_f double precision,
    value_s text,
    value_dt timestamp without time zone
);


ALTER TABLE public.gha_vars OWNER TO gha_admin;

--
-- Name: sannotations; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.sannotations (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    title text DEFAULT ''::text NOT NULL,
    description text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.sannotations OWNER TO gha_admin;

--
-- Name: sbot_commands; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.sbot_commands (
    "time" timestamp without time zone NOT NULL,
    series text NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    "/assign" double precision DEFAULT 0.0 NOT NULL,
    "/cc" double precision DEFAULT 0.0 NOT NULL,
    "/lgtm" double precision DEFAULT 0.0 NOT NULL,
    "/area" double precision DEFAULT 0.0 NOT NULL,
    "/close" double precision DEFAULT 0.0 NOT NULL,
    "/kind" double precision DEFAULT 0.0 NOT NULL,
    "/approve" double precision DEFAULT 0.0 NOT NULL,
    "/test" double precision DEFAULT 0.0 NOT NULL,
    "/lgtm cancel" double precision DEFAULT 0.0 NOT NULL,
    "/hold" double precision DEFAULT 0.0 NOT NULL,
    "/retest" double precision DEFAULT 0.0 NOT NULL,
    "/sig" double precision DEFAULT 0.0 NOT NULL,
    "/lifecycle" double precision DEFAULT 0.0 NOT NULL,
    "/hold cancel" double precision DEFAULT 0.0 NOT NULL,
    "/reopen" double precision DEFAULT 0.0 NOT NULL,
    "/approve no-issue" double precision DEFAULT 0.0 NOT NULL,
    "/ok-to-test" double precision DEFAULT 0.0 NOT NULL,
    "/unassign" double precision DEFAULT 0.0 NOT NULL,
    "/joke" double precision DEFAULT 0.0 NOT NULL,
    "/test all" double precision DEFAULT 0.0 NOT NULL,
    "/release-note" double precision DEFAULT 0.0 NOT NULL,
    "/uncc" double precision DEFAULT 0.0 NOT NULL,
    "/priority" double precision DEFAULT 0.0 NOT NULL,
    "/release-note-none" double precision DEFAULT 0.0 NOT NULL,
    "/remove-sig" double precision DEFAULT 0.0 NOT NULL,
    "/approve cancel" double precision DEFAULT 0.0 NOT NULL,
    "/remove-kind" double precision DEFAULT 0.0 NOT NULL,
    "/remove-priority" double precision DEFAULT 0.0 NOT NULL,
    "/release-note-action-required" double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.sbot_commands OWNER TO gha_admin;

--
-- Name: scompany_activity; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.scompany_activity (
    "time" timestamp without time zone NOT NULL,
    series text NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    "Rackspace" double precision DEFAULT 0.0 NOT NULL,
    "NEC" double precision DEFAULT 0.0 NOT NULL,
    "Google" double precision DEFAULT 0.0 NOT NULL,
    "Weaveworks" double precision DEFAULT 0.0 NOT NULL,
    "Heptio" double precision DEFAULT 0.0 NOT NULL,
    "IBM" double precision DEFAULT 0.0 NOT NULL,
    "Huawei" double precision DEFAULT 0.0 NOT NULL,
    "Infoblox" double precision DEFAULT 0.0 NOT NULL,
    "Alauda" double precision DEFAULT 0.0 NOT NULL,
    "All" double precision DEFAULT 0.0 NOT NULL,
    "Microsoft" double precision DEFAULT 0.0 NOT NULL,
    "Independent" double precision DEFAULT 0.0 NOT NULL,
    "Dell" double precision DEFAULT 0.0 NOT NULL,
    "VMware" double precision DEFAULT 0.0 NOT NULL,
    "Caicloud" double precision DEFAULT 0.0 NOT NULL,
    "Red Hat" double precision DEFAULT 0.0 NOT NULL,
    "Mirantis" double precision DEFAULT 0.0 NOT NULL,
    "Samsung SDS" double precision DEFAULT 0.0 NOT NULL,
    "CNCF" double precision DEFAULT 0.0 NOT NULL,
    "Apprenda" double precision DEFAULT 0.0 NOT NULL,
    "Uber" double precision DEFAULT 0.0 NOT NULL,
    "Tigera" double precision DEFAULT 0.0 NOT NULL,
    "Devops" double precision DEFAULT 0.0 NOT NULL,
    "GoDaddy" double precision DEFAULT 0.0 NOT NULL,
    "CloudFlare" double precision DEFAULT 0.0 NOT NULL,
    "Cisco" double precision DEFAULT 0.0 NOT NULL,
    "EasyStack" double precision DEFAULT 0.0 NOT NULL,
    "HPE" double precision DEFAULT 0.0 NOT NULL,
    "Apple" double precision DEFAULT 0.0 NOT NULL,
    "NFLabs" double precision DEFAULT 0.0 NOT NULL,
    "Bloomberg" double precision DEFAULT 0.0 NOT NULL,
    "Ericsson" double precision DEFAULT 0.0 NOT NULL,
    "Ghostcloud" double precision DEFAULT 0.0 NOT NULL,
    "SUSE" double precision DEFAULT 0.0 NOT NULL,
    "SoundCloud" double precision DEFAULT 0.0 NOT NULL,
    "DaoCloud" double precision DEFAULT 0.0 NOT NULL,
    "Bitnami" double precision DEFAULT 0.0 NOT NULL,
    "Tencent" double precision DEFAULT 0.0 NOT NULL,
    "ZTE" double precision DEFAULT 0.0 NOT NULL,
    "Jd.Com" double precision DEFAULT 0.0 NOT NULL,
    "AT&T" double precision DEFAULT 0.0 NOT NULL,
    "Mesosphere" double precision DEFAULT 0.0 NOT NULL,
    "Yahoo" double precision DEFAULT 0.0 NOT NULL,
    "Fujitsu" double precision DEFAULT 0.0 NOT NULL,
    "SuperAwesome" double precision DEFAULT 0.0 NOT NULL,
    "SalesForce" double precision DEFAULT 0.0 NOT NULL,
    "Pivotal" double precision DEFAULT 0.0 NOT NULL,
    "Amadeus" double precision DEFAULT 0.0 NOT NULL,
    "Zalando" double precision DEFAULT 0.0 NOT NULL,
    "Oracle" double precision DEFAULT 0.0 NOT NULL,
    "ThoughtWorks" double precision DEFAULT 0.0 NOT NULL,
    "eBay" double precision DEFAULT 0.0 NOT NULL,
    "Shopify" double precision DEFAULT 0.0 NOT NULL,
    "Intel" double precision DEFAULT 0.0 NOT NULL,
    "Amazon" double precision DEFAULT 0.0 NOT NULL,
    "Qiniu" double precision DEFAULT 0.0 NOT NULL,
    "Kinvolk" double precision DEFAULT 0.0 NOT NULL,
    "Atlassian" double precision DEFAULT 0.0 NOT NULL,
    "Alibaba" double precision DEFAULT 0.0 NOT NULL,
    "Apcera" double precision DEFAULT 0.0 NOT NULL,
    "Net EASE" double precision DEFAULT 0.0 NOT NULL,
    "SAP" double precision DEFAULT 0.0 NOT NULL,
    "Apache" double precision DEFAULT 0.0 NOT NULL,
    "Docker" double precision DEFAULT 0.0 NOT NULL,
    "Canonical" double precision DEFAULT 0.0 NOT NULL,
    "GitHub" double precision DEFAULT 0.0 NOT NULL,
    "HP" double precision DEFAULT 0.0 NOT NULL,
    "Samsung" double precision DEFAULT 0.0 NOT NULL,
    "EMC" double precision DEFAULT 0.0 NOT NULL,
    "LinkedIn" double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.scompany_activity OWNER TO gha_admin;

--
-- Name: sepisodic_contributors; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.sepisodic_contributors (
    "time" timestamp without time zone NOT NULL,
    series text NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.sepisodic_contributors OWNER TO gha_admin;

--
-- Name: sepisodic_issues; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.sepisodic_issues (
    "time" timestamp without time zone NOT NULL,
    series text NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.sepisodic_issues OWNER TO gha_admin;

--
-- Name: sevents_h; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.sevents_h (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.sevents_h OWNER TO gha_admin;

--
-- Name: sfirst_non_author; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.sfirst_non_author (
    "time" timestamp without time zone NOT NULL,
    series text NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    descr text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.sfirst_non_author OWNER TO gha_admin;

--
-- Name: sgh_stats_r; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.sgh_stats_r (
    "time" timestamp without time zone NOT NULL,
    series text NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    "kubernetes/gengo" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/autoscaler" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/heapster" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/contrib" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/test-infra" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/minikube" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-incubator/bootkube" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/examples" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-csi/drivers" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-client/csharp" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/kubernetes" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/kube-deploy" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/kubernetes-docs-zh" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/sig-release" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-incubator/cri-containerd" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-csi/external-attacher" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-client/python" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/ingress-nginx" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/dashboard" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/node-problem-detector" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-client/python-base" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-sigs/federation-v2" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/kube-state-metrics" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-incubator/descheduler" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-sigs/cluster-api" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-incubator/external-storage" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-sigs/testing_frameworks" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-sigs/controller-runtime" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/kubernetes-docs-ko" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-incubator/rktlet" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-incubator/cri-o" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-incubator/metrics-server" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/git-sync" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/release" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/perf-tests" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/publishing-bot" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-sigs/cluster-api-provider-openstack" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/features" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/kubeadm" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/cloud-provider-vsphere" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/website" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-incubator/external-dns" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-incubator/kube-aws" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/kubectl" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/kompose" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-incubator/cri-tools" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-incubator/service-catalog" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/kube-openapi" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/cloud-provider-openstack" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-sigs/poseidon" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-incubator/cluster-capacity" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-retired/kubernetes-bootcamp" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-sigs/kubeadm-dind-cluster" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/charts" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-incubator/apiserver-builder" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/frakti" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-incubator/kubespray" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/community" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/kops" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/kubernetes-anywhere" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-incubator/node-feature-discovery" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/federation" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-incubator/kube-arbitrator" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/ingress-gce" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-sigs/application" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-sigs/kubebuilder" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-client/javascript" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/cloud-provider-azure" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-sigs/kustomize" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/k8s.io" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-sigs/cluster-api-provider-aws" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-sigs/aws-iam-authenticator" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/dns" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-sigs/aws-alb-ingress-controller" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-retired/kube-mesos-framework" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-client/java" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-sigs/controller-tools" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-csi/docs" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/utils" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-client/go" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-incubator/custom-metrics-apiserver" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/kubernetes-docs-ja" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-incubator/cluster-proportional-autoscaler" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-client/gen" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-csi/csi-test" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/cloud-provider-aws" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/org" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-retired/kubedash" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-sigs/gcp-compute-persistent-disk-csi-driver" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-retired/kube-ui" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-incubator/spartakus" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-retired/typescript" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-sigs/cluster-api-provider-gcp" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/repo-infra" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-incubator/reference-docs" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-csi/driver-registrar" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/cluster-registry" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-sigs/architecture-tracking" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-csi/external-provisioner" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-incubator/nfs-provisioner" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-client/haskell" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/steering" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-csi/kubernetes-csi.github.io" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-csi/external-snapshotter" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-retired/application-images" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-csi/flex-provisioner" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-csi/resources" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/cloud-provider-gcp" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-client/ruby" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-sigs/cluster-api-provider-vsphere" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-sigs/gcp-filestore-csi-driver" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/kubernetes-template-project" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-incubator/ip-masq-agent" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-sigs/foo" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-sigs/contributor-site" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-csi/livenessprobe" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-retired/md-check" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-sigs/aws-encryption-provider" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-retired/community" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-incubator/kube2consul" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-client/go-base" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/common" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-sigs/kube-storage-version-migrator" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/pr-bot" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-incubator/cluster-proportional-vertical-autoscaler" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-sigs/contributor-playground" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes/ocid" double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.sgh_stats_r OWNER TO gha_admin;

--
-- Name: sgh_stats_rgrp; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.sgh_stats_rgrp (
    "time" timestamp without time zone NOT NULL,
    series text NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    "Contrib" double precision DEFAULT 0.0 NOT NULL,
    "Clients" double precision DEFAULT 0.0 NOT NULL,
    "Node" double precision DEFAULT 0.0 NOT NULL,
    "UI" double precision DEFAULT 0.0 NOT NULL,
    "Autoscaling and monitoring" double precision DEFAULT 0.0 NOT NULL,
    "Project" double precision DEFAULT 0.0 NOT NULL,
    "Networking" double precision DEFAULT 0.0 NOT NULL,
    "API machinery" double precision DEFAULT 0.0 NOT NULL,
    "CSI" double precision DEFAULT 0.0 NOT NULL,
    "Kubernetes" double precision DEFAULT 0.0 NOT NULL,
    "Docs" double precision DEFAULT 0.0 NOT NULL,
    "Misc" double precision DEFAULT 0.0 NOT NULL,
    "Apps" double precision DEFAULT 0.0 NOT NULL,
    "Cluster lifecycle" double precision DEFAULT 0.0 NOT NULL,
    "Project infra" double precision DEFAULT 0.0 NOT NULL,
    "SIG Service Catalog" double precision DEFAULT 0.0 NOT NULL,
    "Storage" double precision DEFAULT 0.0 NOT NULL,
    "Multi-cluster" double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.sgh_stats_rgrp OWNER TO gha_admin;

--
-- Name: shcomcommenters; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shcomcommenters (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shcomcommenters OWNER TO gha_admin;

--
-- Name: shcomcomments; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shcomcomments (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shcomcomments OWNER TO gha_admin;

--
-- Name: shcomcommitcommenters; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shcomcommitcommenters (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shcomcommitcommenters OWNER TO gha_admin;

--
-- Name: shcomcommits; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shcomcommits (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shcomcommits OWNER TO gha_admin;

--
-- Name: shcomcommitters; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shcomcommitters (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shcomcommitters OWNER TO gha_admin;

--
-- Name: shcomcontributions; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shcomcontributions (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shcomcontributions OWNER TO gha_admin;

--
-- Name: shcomcontributors; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shcomcontributors (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shcomcontributors OWNER TO gha_admin;

--
-- Name: shcomevents; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shcomevents (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shcomevents OWNER TO gha_admin;

--
-- Name: shcomforkers; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shcomforkers (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shcomforkers OWNER TO gha_admin;

--
-- Name: shcomissuecommenters; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shcomissuecommenters (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shcomissuecommenters OWNER TO gha_admin;

--
-- Name: shcomissuecreators; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shcomissuecreators (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shcomissuecreators OWNER TO gha_admin;

--
-- Name: shcomissues; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shcomissues (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shcomissues OWNER TO gha_admin;

--
-- Name: shcomprcreators; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shcomprcreators (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shcomprcreators OWNER TO gha_admin;

--
-- Name: shcomprreviewers; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shcomprreviewers (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shcomprreviewers OWNER TO gha_admin;

--
-- Name: shcomprs; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shcomprs (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shcomprs OWNER TO gha_admin;

--
-- Name: shcomrepositories; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shcomrepositories (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shcomrepositories OWNER TO gha_admin;

--
-- Name: shcomwatchers; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shcomwatchers (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shcomwatchers OWNER TO gha_admin;

--
-- Name: shdev_active_reposall; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_active_reposall (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_active_reposall OWNER TO gha_admin;

--
-- Name: shdev_active_reposapimachinery; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_active_reposapimachinery (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_active_reposapimachinery OWNER TO gha_admin;

--
-- Name: shdev_active_reposapps; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_active_reposapps (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_active_reposapps OWNER TO gha_admin;

--
-- Name: shdev_active_reposautoscalingandmonitoring; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_active_reposautoscalingandmonitoring (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_active_reposautoscalingandmonitoring OWNER TO gha_admin;

--
-- Name: shdev_active_reposclients; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_active_reposclients (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_active_reposclients OWNER TO gha_admin;

--
-- Name: shdev_active_reposclusterlifecycle; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_active_reposclusterlifecycle (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_active_reposclusterlifecycle OWNER TO gha_admin;

--
-- Name: shdev_active_reposcsi; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_active_reposcsi (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_active_reposcsi OWNER TO gha_admin;

--
-- Name: shdev_active_reposdocs; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_active_reposdocs (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_active_reposdocs OWNER TO gha_admin;

--
-- Name: shdev_active_reposkubernetes; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_active_reposkubernetes (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_active_reposkubernetes OWNER TO gha_admin;

--
-- Name: shdev_active_reposmisc; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_active_reposmisc (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_active_reposmisc OWNER TO gha_admin;

--
-- Name: shdev_active_reposnetworking; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_active_reposnetworking (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_active_reposnetworking OWNER TO gha_admin;

--
-- Name: shdev_active_reposnode; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_active_reposnode (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_active_reposnode OWNER TO gha_admin;

--
-- Name: shdev_active_reposproject; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_active_reposproject (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_active_reposproject OWNER TO gha_admin;

--
-- Name: shdev_active_reposprojectinfra; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_active_reposprojectinfra (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_active_reposprojectinfra OWNER TO gha_admin;

--
-- Name: shdev_active_reposstorage; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_active_reposstorage (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_active_reposstorage OWNER TO gha_admin;

--
-- Name: shdev_active_reposui; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_active_reposui (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_active_reposui OWNER TO gha_admin;

--
-- Name: shdev_approvesall; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_approvesall (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_approvesall OWNER TO gha_admin;

--
-- Name: shdev_approvesapimachinery; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_approvesapimachinery (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_approvesapimachinery OWNER TO gha_admin;

--
-- Name: shdev_approvesapps; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_approvesapps (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_approvesapps OWNER TO gha_admin;

--
-- Name: shdev_approvesautoscalingandmonitoring; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_approvesautoscalingandmonitoring (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_approvesautoscalingandmonitoring OWNER TO gha_admin;

--
-- Name: shdev_approvesclients; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_approvesclients (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_approvesclients OWNER TO gha_admin;

--
-- Name: shdev_approvesclusterlifecycle; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_approvesclusterlifecycle (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_approvesclusterlifecycle OWNER TO gha_admin;

--
-- Name: shdev_approvescontrib; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_approvescontrib (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_approvescontrib OWNER TO gha_admin;

--
-- Name: shdev_approvescsi; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_approvescsi (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_approvescsi OWNER TO gha_admin;

--
-- Name: shdev_approvesdocs; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_approvesdocs (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_approvesdocs OWNER TO gha_admin;

--
-- Name: shdev_approveskubernetes; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_approveskubernetes (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_approveskubernetes OWNER TO gha_admin;

--
-- Name: shdev_approvesmisc; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_approvesmisc (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_approvesmisc OWNER TO gha_admin;

--
-- Name: shdev_approvesmulticluster; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_approvesmulticluster (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_approvesmulticluster OWNER TO gha_admin;

--
-- Name: shdev_approvesnetworking; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_approvesnetworking (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_approvesnetworking OWNER TO gha_admin;

--
-- Name: shdev_approvesnode; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_approvesnode (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_approvesnode OWNER TO gha_admin;

--
-- Name: shdev_approvesproject; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_approvesproject (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_approvesproject OWNER TO gha_admin;

--
-- Name: shdev_approvesprojectinfra; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_approvesprojectinfra (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_approvesprojectinfra OWNER TO gha_admin;

--
-- Name: shdev_approvessigservicecatalog; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_approvessigservicecatalog (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_approvessigservicecatalog OWNER TO gha_admin;

--
-- Name: shdev_approvesstorage; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_approvesstorage (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_approvesstorage OWNER TO gha_admin;

--
-- Name: shdev_approvesui; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_approvesui (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_approvesui OWNER TO gha_admin;

--
-- Name: shdev_commentsall; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commentsall (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commentsall OWNER TO gha_admin;

--
-- Name: shdev_commentsapimachinery; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commentsapimachinery (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commentsapimachinery OWNER TO gha_admin;

--
-- Name: shdev_commentsapps; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commentsapps (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commentsapps OWNER TO gha_admin;

--
-- Name: shdev_commentsautoscalingandmonitoring; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commentsautoscalingandmonitoring (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commentsautoscalingandmonitoring OWNER TO gha_admin;

--
-- Name: shdev_commentsclients; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commentsclients (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commentsclients OWNER TO gha_admin;

--
-- Name: shdev_commentsclusterlifecycle; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commentsclusterlifecycle (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commentsclusterlifecycle OWNER TO gha_admin;

--
-- Name: shdev_commentscontrib; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commentscontrib (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commentscontrib OWNER TO gha_admin;

--
-- Name: shdev_commentscsi; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commentscsi (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commentscsi OWNER TO gha_admin;

--
-- Name: shdev_commentsdocs; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commentsdocs (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commentsdocs OWNER TO gha_admin;

--
-- Name: shdev_commentskubernetes; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commentskubernetes (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_commentskubernetes OWNER TO gha_admin;

--
-- Name: shdev_commentsmisc; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commentsmisc (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commentsmisc OWNER TO gha_admin;

--
-- Name: shdev_commentsmulticluster; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commentsmulticluster (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commentsmulticluster OWNER TO gha_admin;

--
-- Name: shdev_commentsnetworking; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commentsnetworking (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_commentsnetworking OWNER TO gha_admin;

--
-- Name: shdev_commentsnode; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commentsnode (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_commentsnode OWNER TO gha_admin;

--
-- Name: shdev_commentsproject; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commentsproject (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_commentsproject OWNER TO gha_admin;

--
-- Name: shdev_commentsprojectinfra; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commentsprojectinfra (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commentsprojectinfra OWNER TO gha_admin;

--
-- Name: shdev_commentssigservicecatalog; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commentssigservicecatalog (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_commentssigservicecatalog OWNER TO gha_admin;

--
-- Name: shdev_commentsstorage; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commentsstorage (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commentsstorage OWNER TO gha_admin;

--
-- Name: shdev_commentsui; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commentsui (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_commentsui OWNER TO gha_admin;

--
-- Name: shdev_commit_commentsall; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commit_commentsall (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commit_commentsall OWNER TO gha_admin;

--
-- Name: shdev_commit_commentsapps; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commit_commentsapps (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commit_commentsapps OWNER TO gha_admin;

--
-- Name: shdev_commit_commentsautoscalingandmonitoring; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commit_commentsautoscalingandmonitoring (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commit_commentsautoscalingandmonitoring OWNER TO gha_admin;

--
-- Name: shdev_commit_commentsclients; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commit_commentsclients (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commit_commentsclients OWNER TO gha_admin;

--
-- Name: shdev_commit_commentsclusterlifecycle; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commit_commentsclusterlifecycle (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_commit_commentsclusterlifecycle OWNER TO gha_admin;

--
-- Name: shdev_commit_commentscontrib; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commit_commentscontrib (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_commit_commentscontrib OWNER TO gha_admin;

--
-- Name: shdev_commit_commentscsi; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commit_commentscsi (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commit_commentscsi OWNER TO gha_admin;

--
-- Name: shdev_commit_commentsdocs; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commit_commentsdocs (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_commit_commentsdocs OWNER TO gha_admin;

--
-- Name: shdev_commit_commentskubernetes; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commit_commentskubernetes (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commit_commentskubernetes OWNER TO gha_admin;

--
-- Name: shdev_commit_commentsmisc; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commit_commentsmisc (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commit_commentsmisc OWNER TO gha_admin;

--
-- Name: shdev_commit_commentsnetworking; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commit_commentsnetworking (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commit_commentsnetworking OWNER TO gha_admin;

--
-- Name: shdev_commit_commentsnode; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commit_commentsnode (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commit_commentsnode OWNER TO gha_admin;

--
-- Name: shdev_commit_commentsproject; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commit_commentsproject (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commit_commentsproject OWNER TO gha_admin;

--
-- Name: shdev_commit_commentsprojectinfra; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commit_commentsprojectinfra (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commit_commentsprojectinfra OWNER TO gha_admin;

--
-- Name: shdev_commit_commentssigservicecatalog; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commit_commentssigservicecatalog (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_commit_commentssigservicecatalog OWNER TO gha_admin;

--
-- Name: shdev_commit_commentsstorage; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commit_commentsstorage (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commit_commentsstorage OWNER TO gha_admin;

--
-- Name: shdev_commit_commentsui; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commit_commentsui (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_commit_commentsui OWNER TO gha_admin;

--
-- Name: shdev_commitsall; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commitsall (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commitsall OWNER TO gha_admin;

--
-- Name: shdev_commitsapimachinery; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commitsapimachinery (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commitsapimachinery OWNER TO gha_admin;

--
-- Name: shdev_commitsapps; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commitsapps (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commitsapps OWNER TO gha_admin;

--
-- Name: shdev_commitsautoscalingandmonitoring; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commitsautoscalingandmonitoring (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_commitsautoscalingandmonitoring OWNER TO gha_admin;

--
-- Name: shdev_commitsclients; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commitsclients (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_commitsclients OWNER TO gha_admin;

--
-- Name: shdev_commitsclusterlifecycle; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commitsclusterlifecycle (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commitsclusterlifecycle OWNER TO gha_admin;

--
-- Name: shdev_commitscontrib; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commitscontrib (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_commitscontrib OWNER TO gha_admin;

--
-- Name: shdev_commitscsi; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commitscsi (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commitscsi OWNER TO gha_admin;

--
-- Name: shdev_commitsdocs; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commitsdocs (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_commitsdocs OWNER TO gha_admin;

--
-- Name: shdev_commitskubernetes; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commitskubernetes (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commitskubernetes OWNER TO gha_admin;

--
-- Name: shdev_commitsmisc; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commitsmisc (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_commitsmisc OWNER TO gha_admin;

--
-- Name: shdev_commitsmulticluster; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commitsmulticluster (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commitsmulticluster OWNER TO gha_admin;

--
-- Name: shdev_commitsnetworking; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commitsnetworking (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_commitsnetworking OWNER TO gha_admin;

--
-- Name: shdev_commitsnode; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commitsnode (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commitsnode OWNER TO gha_admin;

--
-- Name: shdev_commitsproject; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commitsproject (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_commitsproject OWNER TO gha_admin;

--
-- Name: shdev_commitsprojectinfra; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commitsprojectinfra (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commitsprojectinfra OWNER TO gha_admin;

--
-- Name: shdev_commitssigservicecatalog; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commitssigservicecatalog (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_commitssigservicecatalog OWNER TO gha_admin;

--
-- Name: shdev_commitsstorage; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commitsstorage (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commitsstorage OWNER TO gha_admin;

--
-- Name: shdev_commitsui; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_commitsui (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_commitsui OWNER TO gha_admin;

--
-- Name: shdev_contributionsall; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_contributionsall (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_contributionsall OWNER TO gha_admin;

--
-- Name: shdev_contributionsapimachinery; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_contributionsapimachinery (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_contributionsapimachinery OWNER TO gha_admin;

--
-- Name: shdev_contributionsapps; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_contributionsapps (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_contributionsapps OWNER TO gha_admin;

--
-- Name: shdev_contributionsautoscalingandmonitoring; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_contributionsautoscalingandmonitoring (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_contributionsautoscalingandmonitoring OWNER TO gha_admin;

--
-- Name: shdev_contributionsclients; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_contributionsclients (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_contributionsclients OWNER TO gha_admin;

--
-- Name: shdev_contributionsclusterlifecycle; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_contributionsclusterlifecycle (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_contributionsclusterlifecycle OWNER TO gha_admin;

--
-- Name: shdev_contributionscontrib; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_contributionscontrib (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_contributionscontrib OWNER TO gha_admin;

--
-- Name: shdev_contributionscsi; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_contributionscsi (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_contributionscsi OWNER TO gha_admin;

--
-- Name: shdev_contributionsdocs; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_contributionsdocs (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_contributionsdocs OWNER TO gha_admin;

--
-- Name: shdev_contributionskubernetes; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_contributionskubernetes (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_contributionskubernetes OWNER TO gha_admin;

--
-- Name: shdev_contributionsmisc; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_contributionsmisc (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_contributionsmisc OWNER TO gha_admin;

--
-- Name: shdev_contributionsmulticluster; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_contributionsmulticluster (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_contributionsmulticluster OWNER TO gha_admin;

--
-- Name: shdev_contributionsnetworking; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_contributionsnetworking (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_contributionsnetworking OWNER TO gha_admin;

--
-- Name: shdev_contributionsnode; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_contributionsnode (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_contributionsnode OWNER TO gha_admin;

--
-- Name: shdev_contributionsproject; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_contributionsproject (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_contributionsproject OWNER TO gha_admin;

--
-- Name: shdev_contributionsprojectinfra; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_contributionsprojectinfra (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_contributionsprojectinfra OWNER TO gha_admin;

--
-- Name: shdev_contributionssigservicecatalog; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_contributionssigservicecatalog (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_contributionssigservicecatalog OWNER TO gha_admin;

--
-- Name: shdev_contributionsstorage; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_contributionsstorage (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_contributionsstorage OWNER TO gha_admin;

--
-- Name: shdev_contributionsui; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_contributionsui (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_contributionsui OWNER TO gha_admin;

--
-- Name: shdev_eventsall; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_eventsall (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_eventsall OWNER TO gha_admin;

--
-- Name: shdev_eventsapimachinery; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_eventsapimachinery (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_eventsapimachinery OWNER TO gha_admin;

--
-- Name: shdev_eventsapps; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_eventsapps (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_eventsapps OWNER TO gha_admin;

--
-- Name: shdev_eventsautoscalingandmonitoring; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_eventsautoscalingandmonitoring (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_eventsautoscalingandmonitoring OWNER TO gha_admin;

--
-- Name: shdev_eventsclients; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_eventsclients (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_eventsclients OWNER TO gha_admin;

--
-- Name: shdev_eventsclusterlifecycle; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_eventsclusterlifecycle (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_eventsclusterlifecycle OWNER TO gha_admin;

--
-- Name: shdev_eventscontrib; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_eventscontrib (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_eventscontrib OWNER TO gha_admin;

--
-- Name: shdev_eventscsi; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_eventscsi (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_eventscsi OWNER TO gha_admin;

--
-- Name: shdev_eventsdocs; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_eventsdocs (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_eventsdocs OWNER TO gha_admin;

--
-- Name: shdev_eventskubernetes; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_eventskubernetes (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_eventskubernetes OWNER TO gha_admin;

--
-- Name: shdev_eventsmisc; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_eventsmisc (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_eventsmisc OWNER TO gha_admin;

--
-- Name: shdev_eventsmulticluster; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_eventsmulticluster (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_eventsmulticluster OWNER TO gha_admin;

--
-- Name: shdev_eventsnetworking; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_eventsnetworking (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_eventsnetworking OWNER TO gha_admin;

--
-- Name: shdev_eventsnode; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_eventsnode (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_eventsnode OWNER TO gha_admin;

--
-- Name: shdev_eventsproject; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_eventsproject (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_eventsproject OWNER TO gha_admin;

--
-- Name: shdev_eventsprojectinfra; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_eventsprojectinfra (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_eventsprojectinfra OWNER TO gha_admin;

--
-- Name: shdev_eventssigservicecatalog; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_eventssigservicecatalog (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_eventssigservicecatalog OWNER TO gha_admin;

--
-- Name: shdev_eventsstorage; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_eventsstorage (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_eventsstorage OWNER TO gha_admin;

--
-- Name: shdev_eventsui; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_eventsui (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_eventsui OWNER TO gha_admin;

--
-- Name: shdev_issue_commentsall; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issue_commentsall (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issue_commentsall OWNER TO gha_admin;

--
-- Name: shdev_issue_commentsapimachinery; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issue_commentsapimachinery (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_issue_commentsapimachinery OWNER TO gha_admin;

--
-- Name: shdev_issue_commentsapps; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issue_commentsapps (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_issue_commentsapps OWNER TO gha_admin;

--
-- Name: shdev_issue_commentsautoscalingandmonitoring; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issue_commentsautoscalingandmonitoring (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issue_commentsautoscalingandmonitoring OWNER TO gha_admin;

--
-- Name: shdev_issue_commentsclients; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issue_commentsclients (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issue_commentsclients OWNER TO gha_admin;

--
-- Name: shdev_issue_commentsclusterlifecycle; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issue_commentsclusterlifecycle (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issue_commentsclusterlifecycle OWNER TO gha_admin;

--
-- Name: shdev_issue_commentscontrib; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issue_commentscontrib (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_issue_commentscontrib OWNER TO gha_admin;

--
-- Name: shdev_issue_commentscsi; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issue_commentscsi (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issue_commentscsi OWNER TO gha_admin;

--
-- Name: shdev_issue_commentsdocs; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issue_commentsdocs (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issue_commentsdocs OWNER TO gha_admin;

--
-- Name: shdev_issue_commentskubernetes; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issue_commentskubernetes (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issue_commentskubernetes OWNER TO gha_admin;

--
-- Name: shdev_issue_commentsmisc; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issue_commentsmisc (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issue_commentsmisc OWNER TO gha_admin;

--
-- Name: shdev_issue_commentsmulticluster; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issue_commentsmulticluster (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issue_commentsmulticluster OWNER TO gha_admin;

--
-- Name: shdev_issue_commentsnetworking; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issue_commentsnetworking (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issue_commentsnetworking OWNER TO gha_admin;

--
-- Name: shdev_issue_commentsnode; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issue_commentsnode (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issue_commentsnode OWNER TO gha_admin;

--
-- Name: shdev_issue_commentsproject; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issue_commentsproject (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issue_commentsproject OWNER TO gha_admin;

--
-- Name: shdev_issue_commentsprojectinfra; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issue_commentsprojectinfra (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issue_commentsprojectinfra OWNER TO gha_admin;

--
-- Name: shdev_issue_commentssigservicecatalog; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issue_commentssigservicecatalog (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_issue_commentssigservicecatalog OWNER TO gha_admin;

--
-- Name: shdev_issue_commentsstorage; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issue_commentsstorage (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issue_commentsstorage OWNER TO gha_admin;

--
-- Name: shdev_issue_commentsui; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issue_commentsui (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issue_commentsui OWNER TO gha_admin;

--
-- Name: shdev_issuesall; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issuesall (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issuesall OWNER TO gha_admin;

--
-- Name: shdev_issuesapimachinery; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issuesapimachinery (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issuesapimachinery OWNER TO gha_admin;

--
-- Name: shdev_issuesapps; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issuesapps (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_issuesapps OWNER TO gha_admin;

--
-- Name: shdev_issuesautoscalingandmonitoring; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issuesautoscalingandmonitoring (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issuesautoscalingandmonitoring OWNER TO gha_admin;

--
-- Name: shdev_issuesclients; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issuesclients (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issuesclients OWNER TO gha_admin;

--
-- Name: shdev_issuesclusterlifecycle; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issuesclusterlifecycle (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issuesclusterlifecycle OWNER TO gha_admin;

--
-- Name: shdev_issuescontrib; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issuescontrib (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issuescontrib OWNER TO gha_admin;

--
-- Name: shdev_issuescsi; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issuescsi (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issuescsi OWNER TO gha_admin;

--
-- Name: shdev_issuesdocs; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issuesdocs (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issuesdocs OWNER TO gha_admin;

--
-- Name: shdev_issueskubernetes; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issueskubernetes (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issueskubernetes OWNER TO gha_admin;

--
-- Name: shdev_issuesmisc; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issuesmisc (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_issuesmisc OWNER TO gha_admin;

--
-- Name: shdev_issuesmulticluster; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issuesmulticluster (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_issuesmulticluster OWNER TO gha_admin;

--
-- Name: shdev_issuesnetworking; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issuesnetworking (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issuesnetworking OWNER TO gha_admin;

--
-- Name: shdev_issuesnode; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issuesnode (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issuesnode OWNER TO gha_admin;

--
-- Name: shdev_issuesproject; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issuesproject (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_issuesproject OWNER TO gha_admin;

--
-- Name: shdev_issuesprojectinfra; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issuesprojectinfra (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issuesprojectinfra OWNER TO gha_admin;

--
-- Name: shdev_issuessigservicecatalog; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issuessigservicecatalog (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_issuessigservicecatalog OWNER TO gha_admin;

--
-- Name: shdev_issuesstorage; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issuesstorage (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_issuesstorage OWNER TO gha_admin;

--
-- Name: shdev_issuesui; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_issuesui (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_issuesui OWNER TO gha_admin;

--
-- Name: shdev_prsall; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_prsall (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_prsall OWNER TO gha_admin;

--
-- Name: shdev_prsapimachinery; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_prsapimachinery (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_prsapimachinery OWNER TO gha_admin;

--
-- Name: shdev_prsapps; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_prsapps (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_prsapps OWNER TO gha_admin;

--
-- Name: shdev_prsautoscalingandmonitoring; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_prsautoscalingandmonitoring (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_prsautoscalingandmonitoring OWNER TO gha_admin;

--
-- Name: shdev_prsclients; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_prsclients (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_prsclients OWNER TO gha_admin;

--
-- Name: shdev_prsclusterlifecycle; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_prsclusterlifecycle (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_prsclusterlifecycle OWNER TO gha_admin;

--
-- Name: shdev_prscontrib; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_prscontrib (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_prscontrib OWNER TO gha_admin;

--
-- Name: shdev_prscsi; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_prscsi (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_prscsi OWNER TO gha_admin;

--
-- Name: shdev_prsdocs; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_prsdocs (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_prsdocs OWNER TO gha_admin;

--
-- Name: shdev_prskubernetes; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_prskubernetes (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_prskubernetes OWNER TO gha_admin;

--
-- Name: shdev_prsmisc; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_prsmisc (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_prsmisc OWNER TO gha_admin;

--
-- Name: shdev_prsmulticluster; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_prsmulticluster (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_prsmulticluster OWNER TO gha_admin;

--
-- Name: shdev_prsnetworking; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_prsnetworking (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_prsnetworking OWNER TO gha_admin;

--
-- Name: shdev_prsnode; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_prsnode (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_prsnode OWNER TO gha_admin;

--
-- Name: shdev_prsproject; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_prsproject (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_prsproject OWNER TO gha_admin;

--
-- Name: shdev_prsprojectinfra; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_prsprojectinfra (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_prsprojectinfra OWNER TO gha_admin;

--
-- Name: shdev_prssigservicecatalog; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_prssigservicecatalog (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_prssigservicecatalog OWNER TO gha_admin;

--
-- Name: shdev_prsstorage; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_prsstorage (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_prsstorage OWNER TO gha_admin;

--
-- Name: shdev_prsui; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_prsui (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_prsui OWNER TO gha_admin;

--
-- Name: shdev_pushesall; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_pushesall (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_pushesall OWNER TO gha_admin;

--
-- Name: shdev_pushesapimachinery; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_pushesapimachinery (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_pushesapimachinery OWNER TO gha_admin;

--
-- Name: shdev_pushesapps; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_pushesapps (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_pushesapps OWNER TO gha_admin;

--
-- Name: shdev_pushesautoscalingandmonitoring; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_pushesautoscalingandmonitoring (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_pushesautoscalingandmonitoring OWNER TO gha_admin;

--
-- Name: shdev_pushesclients; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_pushesclients (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_pushesclients OWNER TO gha_admin;

--
-- Name: shdev_pushesclusterlifecycle; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_pushesclusterlifecycle (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_pushesclusterlifecycle OWNER TO gha_admin;

--
-- Name: shdev_pushescontrib; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_pushescontrib (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_pushescontrib OWNER TO gha_admin;

--
-- Name: shdev_pushescsi; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_pushescsi (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_pushescsi OWNER TO gha_admin;

--
-- Name: shdev_pushesdocs; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_pushesdocs (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_pushesdocs OWNER TO gha_admin;

--
-- Name: shdev_pusheskubernetes; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_pusheskubernetes (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_pusheskubernetes OWNER TO gha_admin;

--
-- Name: shdev_pushesmisc; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_pushesmisc (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_pushesmisc OWNER TO gha_admin;

--
-- Name: shdev_pushesmulticluster; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_pushesmulticluster (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_pushesmulticluster OWNER TO gha_admin;

--
-- Name: shdev_pushesnetworking; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_pushesnetworking (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_pushesnetworking OWNER TO gha_admin;

--
-- Name: shdev_pushesnode; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_pushesnode (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_pushesnode OWNER TO gha_admin;

--
-- Name: shdev_pushesproject; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_pushesproject (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_pushesproject OWNER TO gha_admin;

--
-- Name: shdev_pushesprojectinfra; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_pushesprojectinfra (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_pushesprojectinfra OWNER TO gha_admin;

--
-- Name: shdev_pushessigservicecatalog; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_pushessigservicecatalog (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_pushessigservicecatalog OWNER TO gha_admin;

--
-- Name: shdev_pushesstorage; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_pushesstorage (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_pushesstorage OWNER TO gha_admin;

--
-- Name: shdev_pushesui; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_pushesui (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_pushesui OWNER TO gha_admin;

--
-- Name: shdev_review_commentsall; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_review_commentsall (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_review_commentsall OWNER TO gha_admin;

--
-- Name: shdev_review_commentsapimachinery; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_review_commentsapimachinery (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_review_commentsapimachinery OWNER TO gha_admin;

--
-- Name: shdev_review_commentsapps; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_review_commentsapps (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_review_commentsapps OWNER TO gha_admin;

--
-- Name: shdev_review_commentsautoscalingandmonitoring; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_review_commentsautoscalingandmonitoring (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_review_commentsautoscalingandmonitoring OWNER TO gha_admin;

--
-- Name: shdev_review_commentsclients; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_review_commentsclients (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_review_commentsclients OWNER TO gha_admin;

--
-- Name: shdev_review_commentsclusterlifecycle; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_review_commentsclusterlifecycle (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_review_commentsclusterlifecycle OWNER TO gha_admin;

--
-- Name: shdev_review_commentscontrib; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_review_commentscontrib (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_review_commentscontrib OWNER TO gha_admin;

--
-- Name: shdev_review_commentscsi; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_review_commentscsi (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_review_commentscsi OWNER TO gha_admin;

--
-- Name: shdev_review_commentsdocs; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_review_commentsdocs (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_review_commentsdocs OWNER TO gha_admin;

--
-- Name: shdev_review_commentskubernetes; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_review_commentskubernetes (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_review_commentskubernetes OWNER TO gha_admin;

--
-- Name: shdev_review_commentsmisc; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_review_commentsmisc (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_review_commentsmisc OWNER TO gha_admin;

--
-- Name: shdev_review_commentsmulticluster; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_review_commentsmulticluster (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_review_commentsmulticluster OWNER TO gha_admin;

--
-- Name: shdev_review_commentsnetworking; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_review_commentsnetworking (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_review_commentsnetworking OWNER TO gha_admin;

--
-- Name: shdev_review_commentsnode; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_review_commentsnode (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_review_commentsnode OWNER TO gha_admin;

--
-- Name: shdev_review_commentsproject; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_review_commentsproject (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_review_commentsproject OWNER TO gha_admin;

--
-- Name: shdev_review_commentsprojectinfra; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_review_commentsprojectinfra (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_review_commentsprojectinfra OWNER TO gha_admin;

--
-- Name: shdev_review_commentssigservicecatalog; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_review_commentssigservicecatalog (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_review_commentssigservicecatalog OWNER TO gha_admin;

--
-- Name: shdev_review_commentsstorage; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_review_commentsstorage (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_review_commentsstorage OWNER TO gha_admin;

--
-- Name: shdev_review_commentsui; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_review_commentsui (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_review_commentsui OWNER TO gha_admin;

--
-- Name: shdev_reviewsall; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_reviewsall (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_reviewsall OWNER TO gha_admin;

--
-- Name: shdev_reviewsapimachinery; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_reviewsapimachinery (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_reviewsapimachinery OWNER TO gha_admin;

--
-- Name: shdev_reviewsapps; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_reviewsapps (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_reviewsapps OWNER TO gha_admin;

--
-- Name: shdev_reviewsautoscalingandmonitoring; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_reviewsautoscalingandmonitoring (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_reviewsautoscalingandmonitoring OWNER TO gha_admin;

--
-- Name: shdev_reviewsclients; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_reviewsclients (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_reviewsclients OWNER TO gha_admin;

--
-- Name: shdev_reviewsclusterlifecycle; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_reviewsclusterlifecycle (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_reviewsclusterlifecycle OWNER TO gha_admin;

--
-- Name: shdev_reviewscontrib; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_reviewscontrib (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_reviewscontrib OWNER TO gha_admin;

--
-- Name: shdev_reviewscsi; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_reviewscsi (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_reviewscsi OWNER TO gha_admin;

--
-- Name: shdev_reviewsdocs; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_reviewsdocs (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_reviewsdocs OWNER TO gha_admin;

--
-- Name: shdev_reviewskubernetes; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_reviewskubernetes (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_reviewskubernetes OWNER TO gha_admin;

--
-- Name: shdev_reviewsmisc; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_reviewsmisc (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_reviewsmisc OWNER TO gha_admin;

--
-- Name: shdev_reviewsmulticluster; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_reviewsmulticluster (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_reviewsmulticluster OWNER TO gha_admin;

--
-- Name: shdev_reviewsnetworking; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_reviewsnetworking (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_reviewsnetworking OWNER TO gha_admin;

--
-- Name: shdev_reviewsnode; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_reviewsnode (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_reviewsnode OWNER TO gha_admin;

--
-- Name: shdev_reviewsproject; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_reviewsproject (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.shdev_reviewsproject OWNER TO gha_admin;

--
-- Name: shdev_reviewsprojectinfra; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_reviewsprojectinfra (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_reviewsprojectinfra OWNER TO gha_admin;

--
-- Name: shdev_reviewssigservicecatalog; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_reviewssigservicecatalog (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_reviewssigservicecatalog OWNER TO gha_admin;

--
-- Name: shdev_reviewsstorage; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_reviewsstorage (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_reviewsstorage OWNER TO gha_admin;

--
-- Name: shdev_reviewsui; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shdev_reviewsui (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shdev_reviewsui OWNER TO gha_admin;

--
-- Name: shpr_wlsigs; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.shpr_wlsigs (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    rev double precision DEFAULT 0.0 NOT NULL,
    rel double precision DEFAULT 0.0 NOT NULL,
    sig text DEFAULT ''::text NOT NULL,
    iss double precision DEFAULT 0.0 NOT NULL,
    abs double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.shpr_wlsigs OWNER TO gha_admin;

--
-- Name: siclosed_lsk; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.siclosed_lsk (
    "time" timestamp without time zone NOT NULL,
    series text NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.siclosed_lsk OWNER TO gha_admin;

--
-- Name: sissues_age; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.sissues_age (
    "time" timestamp without time zone NOT NULL,
    series text NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    descr text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.sissues_age OWNER TO gha_admin;

--
-- Name: sissues_milestones; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.sissues_milestones (
    "time" timestamp without time zone NOT NULL,
    series text NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.sissues_milestones OWNER TO gha_admin;

--
-- Name: snew_contributors; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.snew_contributors (
    "time" timestamp without time zone NOT NULL,
    series text NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.snew_contributors OWNER TO gha_admin;

--
-- Name: snew_issues; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.snew_issues (
    "time" timestamp without time zone NOT NULL,
    series text NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.snew_issues OWNER TO gha_admin;

--
-- Name: snum_stats; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.snum_stats (
    "time" timestamp without time zone NOT NULL,
    series text NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.snum_stats OWNER TO gha_admin;

--
-- Name: spr_apprappr; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spr_apprappr (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    "All" double precision DEFAULT 0.0 NOT NULL,
    "Autoscaling and monitoring" double precision DEFAULT 0.0 NOT NULL,
    "SIG Service Catalog" double precision DEFAULT 0.0 NOT NULL,
    "API machinery" double precision DEFAULT 0.0 NOT NULL,
    "Kubernetes" double precision DEFAULT 0.0 NOT NULL,
    "Cluster lifecycle" double precision DEFAULT 0.0 NOT NULL,
    "Project infra" double precision DEFAULT 0.0 NOT NULL,
    "Docs" double precision DEFAULT 0.0 NOT NULL,
    "CSI" double precision DEFAULT 0.0 NOT NULL,
    "Node" double precision DEFAULT 0.0 NOT NULL,
    "Project" double precision DEFAULT 0.0 NOT NULL,
    "Networking" double precision DEFAULT 0.0 NOT NULL,
    "Multi-cluster" double precision DEFAULT 0.0 NOT NULL,
    "Misc" double precision DEFAULT 0.0 NOT NULL,
    "Storage" double precision DEFAULT 0.0 NOT NULL,
    "UI" double precision DEFAULT 0.0 NOT NULL,
    "Contrib" double precision DEFAULT 0.0 NOT NULL,
    "Apps" double precision DEFAULT 0.0 NOT NULL,
    "Clients" double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spr_apprappr OWNER TO gha_admin;

--
-- Name: spr_apprwait; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spr_apprwait (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    "CSI" double precision DEFAULT 0.0 NOT NULL,
    "Storage" double precision DEFAULT 0.0 NOT NULL,
    "Contrib" double precision DEFAULT 0.0 NOT NULL,
    "UI" double precision DEFAULT 0.0 NOT NULL,
    "Autoscaling and monitoring" double precision DEFAULT 0.0 NOT NULL,
    "Networking" double precision DEFAULT 0.0 NOT NULL,
    "Cluster lifecycle" double precision DEFAULT 0.0 NOT NULL,
    "Apps" double precision DEFAULT 0.0 NOT NULL,
    "Project infra" double precision DEFAULT 0.0 NOT NULL,
    "Docs" double precision DEFAULT 0.0 NOT NULL,
    "Node" double precision DEFAULT 0.0 NOT NULL,
    "Clients" double precision DEFAULT 0.0 NOT NULL,
    "Misc" double precision DEFAULT 0.0 NOT NULL,
    "Multi-cluster" double precision DEFAULT 0.0 NOT NULL,
    "All" double precision DEFAULT 0.0 NOT NULL,
    "SIG Service Catalog" double precision DEFAULT 0.0 NOT NULL,
    "Project" double precision DEFAULT 0.0 NOT NULL,
    "API machinery" double precision DEFAULT 0.0 NOT NULL,
    "Kubernetes" double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spr_apprwait OWNER TO gha_admin;

--
-- Name: spr_authall; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spr_authall (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spr_authall OWNER TO gha_admin;

--
-- Name: spr_authapimachinery; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spr_authapimachinery (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spr_authapimachinery OWNER TO gha_admin;

--
-- Name: spr_authapps; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spr_authapps (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spr_authapps OWNER TO gha_admin;

--
-- Name: spr_authautoscalingandmonitoring; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spr_authautoscalingandmonitoring (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spr_authautoscalingandmonitoring OWNER TO gha_admin;

--
-- Name: spr_authclients; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spr_authclients (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spr_authclients OWNER TO gha_admin;

--
-- Name: spr_authclusterlifecycle; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spr_authclusterlifecycle (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spr_authclusterlifecycle OWNER TO gha_admin;

--
-- Name: spr_authcontrib; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spr_authcontrib (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spr_authcontrib OWNER TO gha_admin;

--
-- Name: spr_authcsi; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spr_authcsi (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spr_authcsi OWNER TO gha_admin;

--
-- Name: spr_authdocs; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spr_authdocs (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spr_authdocs OWNER TO gha_admin;

--
-- Name: spr_authkubernetes; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spr_authkubernetes (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spr_authkubernetes OWNER TO gha_admin;

--
-- Name: spr_authmisc; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spr_authmisc (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spr_authmisc OWNER TO gha_admin;

--
-- Name: spr_authmulticluster; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spr_authmulticluster (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spr_authmulticluster OWNER TO gha_admin;

--
-- Name: spr_authnetworking; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spr_authnetworking (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spr_authnetworking OWNER TO gha_admin;

--
-- Name: spr_authnode; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spr_authnode (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spr_authnode OWNER TO gha_admin;

--
-- Name: spr_authproject; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spr_authproject (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spr_authproject OWNER TO gha_admin;

--
-- Name: spr_authprojectinfra; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spr_authprojectinfra (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spr_authprojectinfra OWNER TO gha_admin;

--
-- Name: spr_authsigservicecatalog; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spr_authsigservicecatalog (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spr_authsigservicecatalog OWNER TO gha_admin;

--
-- Name: spr_authstorage; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spr_authstorage (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spr_authstorage OWNER TO gha_admin;

--
-- Name: spr_authui; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spr_authui (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spr_authui OWNER TO gha_admin;

--
-- Name: spr_comms_med; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spr_comms_med (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spr_comms_med OWNER TO gha_admin;

--
-- Name: spr_comms_p85; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spr_comms_p85 (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spr_comms_p85 OWNER TO gha_admin;

--
-- Name: spr_comms_p95; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spr_comms_p95 (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spr_comms_p95 OWNER TO gha_admin;

--
-- Name: sprblckall; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.sprblckall (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    "API machinery" double precision DEFAULT 0.0 NOT NULL,
    "Apps" double precision DEFAULT 0.0 NOT NULL,
    "Node" double precision DEFAULT 0.0 NOT NULL,
    "Multi-cluster" double precision DEFAULT 0.0 NOT NULL,
    "All" double precision DEFAULT 0.0 NOT NULL,
    "Contrib" double precision DEFAULT 0.0 NOT NULL,
    "Clients" double precision DEFAULT 0.0 NOT NULL,
    "SIG Service Catalog" double precision DEFAULT 0.0 NOT NULL,
    "Networking" double precision DEFAULT 0.0 NOT NULL,
    "Docs" double precision DEFAULT 0.0 NOT NULL,
    "Storage" double precision DEFAULT 0.0 NOT NULL,
    "Kubernetes" double precision DEFAULT 0.0 NOT NULL,
    "Cluster lifecycle" double precision DEFAULT 0.0 NOT NULL,
    "Autoscaling and monitoring" double precision DEFAULT 0.0 NOT NULL,
    "UI" double precision DEFAULT 0.0 NOT NULL,
    "Project infra" double precision DEFAULT 0.0 NOT NULL,
    "Project" double precision DEFAULT 0.0 NOT NULL,
    "CSI" double precision DEFAULT 0.0 NOT NULL,
    "Misc" double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.sprblckall OWNER TO gha_admin;

--
-- Name: sprblckdo_not_merge; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.sprblckdo_not_merge (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    "Kubernetes" double precision DEFAULT 0.0 NOT NULL,
    "All" double precision DEFAULT 0.0 NOT NULL,
    "Autoscaling and monitoring" double precision DEFAULT 0.0 NOT NULL,
    "Project infra" double precision DEFAULT 0.0 NOT NULL,
    "Project" double precision DEFAULT 0.0 NOT NULL,
    "Docs" double precision DEFAULT 0.0 NOT NULL,
    "Contrib" double precision DEFAULT 0.0 NOT NULL,
    "Networking" double precision DEFAULT 0.0 NOT NULL,
    "API machinery" double precision DEFAULT 0.0 NOT NULL,
    "Node" double precision DEFAULT 0.0 NOT NULL,
    "Apps" double precision DEFAULT 0.0 NOT NULL,
    "Clients" double precision DEFAULT 0.0 NOT NULL,
    "UI" double precision DEFAULT 0.0 NOT NULL,
    "Cluster lifecycle" double precision DEFAULT 0.0 NOT NULL,
    "SIG Service Catalog" double precision DEFAULT 0.0 NOT NULL,
    "Storage" double precision DEFAULT 0.0 NOT NULL,
    "Multi-cluster" double precision DEFAULT 0.0 NOT NULL,
    "CSI" double precision DEFAULT 0.0 NOT NULL,
    "Misc" double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.sprblckdo_not_merge OWNER TO gha_admin;

--
-- Name: sprblckneeds_ok_to_test; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.sprblckneeds_ok_to_test (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    "API machinery" double precision DEFAULT 0.0 NOT NULL,
    "Networking" double precision DEFAULT 0.0 NOT NULL,
    "Autoscaling and monitoring" double precision DEFAULT 0.0 NOT NULL,
    "Project" double precision DEFAULT 0.0 NOT NULL,
    "Multi-cluster" double precision DEFAULT 0.0 NOT NULL,
    "SIG Service Catalog" double precision DEFAULT 0.0 NOT NULL,
    "All" double precision DEFAULT 0.0 NOT NULL,
    "Cluster lifecycle" double precision DEFAULT 0.0 NOT NULL,
    "Project infra" double precision DEFAULT 0.0 NOT NULL,
    "Node" double precision DEFAULT 0.0 NOT NULL,
    "Apps" double precision DEFAULT 0.0 NOT NULL,
    "Docs" double precision DEFAULT 0.0 NOT NULL,
    "Storage" double precision DEFAULT 0.0 NOT NULL,
    "Kubernetes" double precision DEFAULT 0.0 NOT NULL,
    "UI" double precision DEFAULT 0.0 NOT NULL,
    "Contrib" double precision DEFAULT 0.0 NOT NULL,
    "Clients" double precision DEFAULT 0.0 NOT NULL,
    "CSI" double precision DEFAULT 0.0 NOT NULL,
    "Misc" double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.sprblckneeds_ok_to_test OWNER TO gha_admin;

--
-- Name: sprblckno_approve; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.sprblckno_approve (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    "Docs" double precision DEFAULT 0.0 NOT NULL,
    "Project" double precision DEFAULT 0.0 NOT NULL,
    "Networking" double precision DEFAULT 0.0 NOT NULL,
    "Project infra" double precision DEFAULT 0.0 NOT NULL,
    "Storage" double precision DEFAULT 0.0 NOT NULL,
    "All" double precision DEFAULT 0.0 NOT NULL,
    "Kubernetes" double precision DEFAULT 0.0 NOT NULL,
    "Autoscaling and monitoring" double precision DEFAULT 0.0 NOT NULL,
    "Apps" double precision DEFAULT 0.0 NOT NULL,
    "API machinery" double precision DEFAULT 0.0 NOT NULL,
    "Clients" double precision DEFAULT 0.0 NOT NULL,
    "SIG Service Catalog" double precision DEFAULT 0.0 NOT NULL,
    "Multi-cluster" double precision DEFAULT 0.0 NOT NULL,
    "UI" double precision DEFAULT 0.0 NOT NULL,
    "Cluster lifecycle" double precision DEFAULT 0.0 NOT NULL,
    "Contrib" double precision DEFAULT 0.0 NOT NULL,
    "Node" double precision DEFAULT 0.0 NOT NULL,
    "Misc" double precision DEFAULT 0.0 NOT NULL,
    "CSI" double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.sprblckno_approve OWNER TO gha_admin;

--
-- Name: sprblckno_lgtm; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.sprblckno_lgtm (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    "Autoscaling and monitoring" double precision DEFAULT 0.0 NOT NULL,
    "Contrib" double precision DEFAULT 0.0 NOT NULL,
    "SIG Service Catalog" double precision DEFAULT 0.0 NOT NULL,
    "Project" double precision DEFAULT 0.0 NOT NULL,
    "Networking" double precision DEFAULT 0.0 NOT NULL,
    "API machinery" double precision DEFAULT 0.0 NOT NULL,
    "Apps" double precision DEFAULT 0.0 NOT NULL,
    "All" double precision DEFAULT 0.0 NOT NULL,
    "UI" double precision DEFAULT 0.0 NOT NULL,
    "Cluster lifecycle" double precision DEFAULT 0.0 NOT NULL,
    "Project infra" double precision DEFAULT 0.0 NOT NULL,
    "Clients" double precision DEFAULT 0.0 NOT NULL,
    "Docs" double precision DEFAULT 0.0 NOT NULL,
    "Storage" double precision DEFAULT 0.0 NOT NULL,
    "Kubernetes" double precision DEFAULT 0.0 NOT NULL,
    "Node" double precision DEFAULT 0.0 NOT NULL,
    "Multi-cluster" double precision DEFAULT 0.0 NOT NULL,
    "Misc" double precision DEFAULT 0.0 NOT NULL,
    "CSI" double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.sprblckno_lgtm OWNER TO gha_admin;

--
-- Name: sprblckrelease_note_label_needed; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.sprblckrelease_note_label_needed (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    "Apps" double precision DEFAULT 0.0 NOT NULL,
    "Clients" double precision DEFAULT 0.0 NOT NULL,
    "Networking" double precision DEFAULT 0.0 NOT NULL,
    "API machinery" double precision DEFAULT 0.0 NOT NULL,
    "Storage" double precision DEFAULT 0.0 NOT NULL,
    "Multi-cluster" double precision DEFAULT 0.0 NOT NULL,
    "All" double precision DEFAULT 0.0 NOT NULL,
    "Cluster lifecycle" double precision DEFAULT 0.0 NOT NULL,
    "Contrib" double precision DEFAULT 0.0 NOT NULL,
    "SIG Service Catalog" double precision DEFAULT 0.0 NOT NULL,
    "Project infra" double precision DEFAULT 0.0 NOT NULL,
    "Node" double precision DEFAULT 0.0 NOT NULL,
    "Autoscaling and monitoring" double precision DEFAULT 0.0 NOT NULL,
    "UI" double precision DEFAULT 0.0 NOT NULL,
    "Kubernetes" double precision DEFAULT 0.0 NOT NULL,
    "Project" double precision DEFAULT 0.0 NOT NULL,
    "Docs" double precision DEFAULT 0.0 NOT NULL,
    "CSI" double precision DEFAULT 0.0 NOT NULL,
    "Misc" double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.sprblckrelease_note_label_needed OWNER TO gha_admin;

--
-- Name: sprs_age; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.sprs_age (
    "time" timestamp without time zone NOT NULL,
    series text NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    descr text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.sprs_age OWNER TO gha_admin;

--
-- Name: sprs_labels; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.sprs_labels (
    "time" timestamp without time zone NOT NULL,
    series text NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.sprs_labels OWNER TO gha_admin;

--
-- Name: sprs_milestones; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.sprs_milestones (
    "time" timestamp without time zone NOT NULL,
    series text NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.sprs_milestones OWNER TO gha_admin;

--
-- Name: spstatall; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spstatall (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spstatall OWNER TO gha_admin;

--
-- Name: spstatapimachinery; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spstatapimachinery (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spstatapimachinery OWNER TO gha_admin;

--
-- Name: spstatapps; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spstatapps (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.spstatapps OWNER TO gha_admin;

--
-- Name: spstatautoscalingandmonitoring; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spstatautoscalingandmonitoring (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.spstatautoscalingandmonitoring OWNER TO gha_admin;

--
-- Name: spstatclients; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spstatclients (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.spstatclients OWNER TO gha_admin;

--
-- Name: spstatclusterlifecycle; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spstatclusterlifecycle (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spstatclusterlifecycle OWNER TO gha_admin;

--
-- Name: spstatcontrib; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spstatcontrib (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spstatcontrib OWNER TO gha_admin;

--
-- Name: spstatcsi; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spstatcsi (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.spstatcsi OWNER TO gha_admin;

--
-- Name: spstatdocs; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spstatdocs (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spstatdocs OWNER TO gha_admin;

--
-- Name: spstatkubernetes; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spstatkubernetes (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.spstatkubernetes OWNER TO gha_admin;

--
-- Name: spstatmisc; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spstatmisc (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spstatmisc OWNER TO gha_admin;

--
-- Name: spstatmulticluster; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spstatmulticluster (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.spstatmulticluster OWNER TO gha_admin;

--
-- Name: spstatnetworking; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spstatnetworking (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spstatnetworking OWNER TO gha_admin;

--
-- Name: spstatnode; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spstatnode (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spstatnode OWNER TO gha_admin;

--
-- Name: spstatproject; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spstatproject (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spstatproject OWNER TO gha_admin;

--
-- Name: spstatprojectinfra; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spstatprojectinfra (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spstatprojectinfra OWNER TO gha_admin;

--
-- Name: spstatsigservicecatalog; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spstatsigservicecatalog (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spstatsigservicecatalog OWNER TO gha_admin;

--
-- Name: spstatstorage; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spstatstorage (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.spstatstorage OWNER TO gha_admin;

--
-- Name: spstatui; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.spstatui (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.spstatui OWNER TO gha_admin;

--
-- Name: ssig_pr_wlabs; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.ssig_pr_wlabs (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    aws double precision DEFAULT 0.0 NOT NULL,
    ui double precision DEFAULT 0.0 NOT NULL,
    node double precision DEFAULT 0.0 NOT NULL,
    scalability double precision DEFAULT 0.0 NOT NULL,
    "api-machinery" double precision DEFAULT 0.0 NOT NULL,
    federation double precision DEFAULT 0.0 NOT NULL,
    testing double precision DEFAULT 0.0 NOT NULL,
    auth double precision DEFAULT 0.0 NOT NULL,
    instrumentation double precision DEFAULT 0.0 NOT NULL,
    "cluster-ops" double precision DEFAULT 0.0 NOT NULL,
    "contributor-experience" double precision DEFAULT 0.0 NOT NULL,
    "big-data" double precision DEFAULT 0.0 NOT NULL,
    vmware double precision DEFAULT 0.0 NOT NULL,
    onprem double precision DEFAULT 0.0 NOT NULL,
    autoscaling double precision DEFAULT 0.0 NOT NULL,
    release double precision DEFAULT 0.0 NOT NULL,
    architecture double precision DEFAULT 0.0 NOT NULL,
    rktnetes double precision DEFAULT 0.0 NOT NULL,
    gcp double precision DEFAULT 0.0 NOT NULL,
    scheduling double precision DEFAULT 0.0 NOT NULL,
    openstack double precision DEFAULT 0.0 NOT NULL,
    network double precision DEFAULT 0.0 NOT NULL,
    windows double precision DEFAULT 0.0 NOT NULL,
    docs double precision DEFAULT 0.0 NOT NULL,
    pm double precision DEFAULT 0.0 NOT NULL,
    cli double precision DEFAULT 0.0 NOT NULL,
    "service-catalog" double precision DEFAULT 0.0 NOT NULL,
    "cloud-provider" double precision DEFAULT 0.0 NOT NULL,
    "cluster-lifecycle" double precision DEFAULT 0.0 NOT NULL,
    apps double precision DEFAULT 0.0 NOT NULL,
    multicluster double precision DEFAULT 0.0 NOT NULL,
    storage double precision DEFAULT 0.0 NOT NULL,
    azure double precision DEFAULT 0.0 NOT NULL,
    "contrib-ex" double precision DEFAULT 0.0 NOT NULL,
    ibmcloud double precision DEFAULT 0.0 NOT NULL,
    "cluster-federation" double precision DEFAULT 0.0 NOT NULL,
    batchd double precision DEFAULT 0.0 NOT NULL,
    "cluster-fifecycle" double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.ssig_pr_wlabs OWNER TO gha_admin;

--
-- Name: ssig_pr_wliss; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.ssig_pr_wliss (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    docs double precision DEFAULT 0.0 NOT NULL,
    pm double precision DEFAULT 0.0 NOT NULL,
    instrumentation double precision DEFAULT 0.0 NOT NULL,
    windows double precision DEFAULT 0.0 NOT NULL,
    architecture double precision DEFAULT 0.0 NOT NULL,
    gcp double precision DEFAULT 0.0 NOT NULL,
    federation double precision DEFAULT 0.0 NOT NULL,
    release double precision DEFAULT 0.0 NOT NULL,
    "cluster-lifecycle" double precision DEFAULT 0.0 NOT NULL,
    azure double precision DEFAULT 0.0 NOT NULL,
    "cluster-ops" double precision DEFAULT 0.0 NOT NULL,
    "cloud-provider" double precision DEFAULT 0.0 NOT NULL,
    testing double precision DEFAULT 0.0 NOT NULL,
    aws double precision DEFAULT 0.0 NOT NULL,
    "big-data" double precision DEFAULT 0.0 NOT NULL,
    autoscaling double precision DEFAULT 0.0 NOT NULL,
    ui double precision DEFAULT 0.0 NOT NULL,
    scalability double precision DEFAULT 0.0 NOT NULL,
    vmware double precision DEFAULT 0.0 NOT NULL,
    node double precision DEFAULT 0.0 NOT NULL,
    auth double precision DEFAULT 0.0 NOT NULL,
    storage double precision DEFAULT 0.0 NOT NULL,
    multicluster double precision DEFAULT 0.0 NOT NULL,
    onprem double precision DEFAULT 0.0 NOT NULL,
    "api-machinery" double precision DEFAULT 0.0 NOT NULL,
    scheduling double precision DEFAULT 0.0 NOT NULL,
    cli double precision DEFAULT 0.0 NOT NULL,
    openstack double precision DEFAULT 0.0 NOT NULL,
    network double precision DEFAULT 0.0 NOT NULL,
    apps double precision DEFAULT 0.0 NOT NULL,
    "service-catalog" double precision DEFAULT 0.0 NOT NULL,
    rktnetes double precision DEFAULT 0.0 NOT NULL,
    "contributor-experience" double precision DEFAULT 0.0 NOT NULL,
    "contrib-ex" double precision DEFAULT 0.0 NOT NULL,
    ibmcloud double precision DEFAULT 0.0 NOT NULL,
    "cluster-federation" double precision DEFAULT 0.0 NOT NULL,
    batchd double precision DEFAULT 0.0 NOT NULL,
    "cluster-fifecycle" double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.ssig_pr_wliss OWNER TO gha_admin;

--
-- Name: ssig_pr_wlrel; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.ssig_pr_wlrel (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    "cloud-provider" double precision DEFAULT 0.0 NOT NULL,
    scalability double precision DEFAULT 0.0 NOT NULL,
    openstack double precision DEFAULT 0.0 NOT NULL,
    auth double precision DEFAULT 0.0 NOT NULL,
    azure double precision DEFAULT 0.0 NOT NULL,
    release double precision DEFAULT 0.0 NOT NULL,
    "service-catalog" double precision DEFAULT 0.0 NOT NULL,
    gcp double precision DEFAULT 0.0 NOT NULL,
    node double precision DEFAULT 0.0 NOT NULL,
    rktnetes double precision DEFAULT 0.0 NOT NULL,
    apps double precision DEFAULT 0.0 NOT NULL,
    pm double precision DEFAULT 0.0 NOT NULL,
    multicluster double precision DEFAULT 0.0 NOT NULL,
    "big-data" double precision DEFAULT 0.0 NOT NULL,
    federation double precision DEFAULT 0.0 NOT NULL,
    aws double precision DEFAULT 0.0 NOT NULL,
    instrumentation double precision DEFAULT 0.0 NOT NULL,
    windows double precision DEFAULT 0.0 NOT NULL,
    scheduling double precision DEFAULT 0.0 NOT NULL,
    ui double precision DEFAULT 0.0 NOT NULL,
    onprem double precision DEFAULT 0.0 NOT NULL,
    "api-machinery" double precision DEFAULT 0.0 NOT NULL,
    "cluster-ops" double precision DEFAULT 0.0 NOT NULL,
    architecture double precision DEFAULT 0.0 NOT NULL,
    "contributor-experience" double precision DEFAULT 0.0 NOT NULL,
    storage double precision DEFAULT 0.0 NOT NULL,
    network double precision DEFAULT 0.0 NOT NULL,
    docs double precision DEFAULT 0.0 NOT NULL,
    "cluster-lifecycle" double precision DEFAULT 0.0 NOT NULL,
    vmware double precision DEFAULT 0.0 NOT NULL,
    cli double precision DEFAULT 0.0 NOT NULL,
    autoscaling double precision DEFAULT 0.0 NOT NULL,
    testing double precision DEFAULT 0.0 NOT NULL,
    "contrib-ex" double precision DEFAULT 0.0 NOT NULL,
    ibmcloud double precision DEFAULT 0.0 NOT NULL,
    "cluster-federation" double precision DEFAULT 0.0 NOT NULL,
    batchd double precision DEFAULT 0.0 NOT NULL,
    "cluster-fifecycle" double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.ssig_pr_wlrel OWNER TO gha_admin;

--
-- Name: ssig_pr_wlrev; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.ssig_pr_wlrev (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    gcp double precision DEFAULT 0.0 NOT NULL,
    "cluster-lifecycle" double precision DEFAULT 0.0 NOT NULL,
    auth double precision DEFAULT 0.0 NOT NULL,
    instrumentation double precision DEFAULT 0.0 NOT NULL,
    docs double precision DEFAULT 0.0 NOT NULL,
    release double precision DEFAULT 0.0 NOT NULL,
    architecture double precision DEFAULT 0.0 NOT NULL,
    multicluster double precision DEFAULT 0.0 NOT NULL,
    vmware double precision DEFAULT 0.0 NOT NULL,
    storage double precision DEFAULT 0.0 NOT NULL,
    scheduling double precision DEFAULT 0.0 NOT NULL,
    "contributor-experience" double precision DEFAULT 0.0 NOT NULL,
    network double precision DEFAULT 0.0 NOT NULL,
    "cluster-ops" double precision DEFAULT 0.0 NOT NULL,
    pm double precision DEFAULT 0.0 NOT NULL,
    aws double precision DEFAULT 0.0 NOT NULL,
    windows double precision DEFAULT 0.0 NOT NULL,
    federation double precision DEFAULT 0.0 NOT NULL,
    "api-machinery" double precision DEFAULT 0.0 NOT NULL,
    ui double precision DEFAULT 0.0 NOT NULL,
    testing double precision DEFAULT 0.0 NOT NULL,
    cli double precision DEFAULT 0.0 NOT NULL,
    azure double precision DEFAULT 0.0 NOT NULL,
    openstack double precision DEFAULT 0.0 NOT NULL,
    autoscaling double precision DEFAULT 0.0 NOT NULL,
    scalability double precision DEFAULT 0.0 NOT NULL,
    "cloud-provider" double precision DEFAULT 0.0 NOT NULL,
    node double precision DEFAULT 0.0 NOT NULL,
    apps double precision DEFAULT 0.0 NOT NULL,
    "service-catalog" double precision DEFAULT 0.0 NOT NULL,
    onprem double precision DEFAULT 0.0 NOT NULL,
    rktnetes double precision DEFAULT 0.0 NOT NULL,
    "big-data" double precision DEFAULT 0.0 NOT NULL,
    "contrib-ex" double precision DEFAULT 0.0 NOT NULL,
    ibmcloud double precision DEFAULT 0.0 NOT NULL,
    "cluster-federation" double precision DEFAULT 0.0 NOT NULL,
    batchd double precision DEFAULT 0.0 NOT NULL,
    "cluster-fifecycle" double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.ssig_pr_wlrev OWNER TO gha_admin;

--
-- Name: ssigm_lsk; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.ssigm_lsk (
    "time" timestamp without time zone NOT NULL,
    series text NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.ssigm_lsk OWNER TO gha_admin;

--
-- Name: ssigm_txt; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.ssigm_txt (
    "time" timestamp without time zone NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    scalability double precision DEFAULT 0.0 NOT NULL,
    config double precision DEFAULT 0.0 NOT NULL,
    auth double precision DEFAULT 0.0 NOT NULL,
    testing double precision DEFAULT 0.0 NOT NULL,
    "cluster-lifecycle" double precision DEFAULT 0.0 NOT NULL,
    apps double precision DEFAULT 0.0 NOT NULL,
    "cli-maintainers" double precision DEFAULT 0.0 NOT NULL,
    network double precision DEFAULT 0.0 NOT NULL,
    "contributor-experience" double precision DEFAULT 0.0 NOT NULL,
    cli double precision DEFAULT 0.0 NOT NULL,
    federation double precision DEFAULT 0.0 NOT NULL,
    aws double precision DEFAULT 0.0 NOT NULL,
    autoscaling double precision DEFAULT 0.0 NOT NULL,
    multicluster double precision DEFAULT 0.0 NOT NULL,
    storage double precision DEFAULT 0.0 NOT NULL,
    "api-machinery" double precision DEFAULT 0.0 NOT NULL,
    apimachinery double precision DEFAULT 0.0 NOT NULL,
    "docs-maintainers" double precision DEFAULT 0.0 NOT NULL,
    instrumentation double precision DEFAULT 0.0 NOT NULL,
    "cluster-federation" double precision DEFAULT 0.0 NOT NULL,
    node double precision DEFAULT 0.0 NOT NULL,
    scheduling double precision DEFAULT 0.0 NOT NULL,
    openstack double precision DEFAULT 0.0 NOT NULL,
    "test-failures" double precision DEFAULT 0.0 NOT NULL,
    azure double precision DEFAULT 0.0 NOT NULL,
    gcp double precision DEFAULT 0.0 NOT NULL,
    "storage-experience" double precision DEFAULT 0.0 NOT NULL,
    architecture double precision DEFAULT 0.0 NOT NULL,
    release double precision DEFAULT 0.0 NOT NULL,
    "controller-manager" double precision DEFAULT 0.0 NOT NULL,
    windows double precision DEFAULT 0.0 NOT NULL,
    rktnetes double precision DEFAULT 0.0 NOT NULL,
    docs double precision DEFAULT 0.0 NOT NULL,
    "big-data" double precision DEFAULT 0.0 NOT NULL,
    "release-members" double precision DEFAULT 0.0 NOT NULL,
    "cluster-ops" double precision DEFAULT 0.0 NOT NULL,
    scheduler double precision DEFAULT 0.0 NOT NULL,
    "autoscaling-bugsteam" double precision DEFAULT 0.0 NOT NULL,
    bugs double precision DEFAULT 0.0 NOT NULL,
    onprem double precision DEFAULT 0.0 NOT NULL,
    networking double precision DEFAULT 0.0 NOT NULL,
    "node-reviewers" double precision DEFAULT 0.0 NOT NULL,
    "kubernetes-client" double precision DEFAULT 0.0 NOT NULL,
    "release-admins" double precision DEFAULT 0.0 NOT NULL,
    ui double precision DEFAULT 0.0 NOT NULL,
    "instrumentation-oh-you-dont-have-teams-yet" double precision DEFAULT 0.0 NOT NULL,
    "auth-feature" double precision DEFAULT 0.0 NOT NULL,
    app double precision DEFAULT 0.0 NOT NULL,
    kops double precision DEFAULT 0.0 NOT NULL,
    "cloud-provider" double precision DEFAULT 0.0 NOT NULL,
    "cluster-api" double precision DEFAULT 0.0 NOT NULL,
    "service-catalog" double precision DEFAULT 0.0 NOT NULL,
    cloud double precision DEFAULT 0.0 NOT NULL,
    cluster double precision DEFAULT 0.0 NOT NULL,
    "contributor-experience-misc-use-only-as-a-last-resort" double precision DEFAULT 0.0 NOT NULL,
    kubeadm double precision DEFAULT 0.0 NOT NULL,
    "docs-ko-owners" double precision DEFAULT 0.0 NOT NULL,
    "network-services" double precision DEFAULT 0.0 NOT NULL,
    "apps-features" double precision DEFAULT 0.0 NOT NULL,
    "node-kubelet" double precision DEFAULT 0.0 NOT NULL,
    "kube-apiserver" double precision DEFAULT 0.0 NOT NULL,
    "kubeadm-feature" double precision DEFAULT 0.0 NOT NULL,
    "node-hepl" double precision DEFAULT 0.0 NOT NULL,
    hepl double precision DEFAULT 0.0 NOT NULL,
    "architecture-misc-use-only-as-a-last-resort" double precision DEFAULT 0.0 NOT NULL,
    apiserver double precision DEFAULT 0.0 NOT NULL,
    controller double precision DEFAULT 0.0 NOT NULL,
    api double precision DEFAULT 0.0 NOT NULL,
    "cluster-container" double precision DEFAULT 0.0 NOT NULL,
    area double precision DEFAULT 0.0 NOT NULL,
    minikube double precision DEFAULT 0.0 NOT NULL,
    "azure-azure" double precision DEFAULT 0.0 NOT NULL,
    dns double precision DEFAULT 0.0 NOT NULL,
    storge double precision DEFAULT 0.0 NOT NULL,
    foo double precision DEFAULT 0.0 NOT NULL,
    monitoring double precision DEFAULT 0.0 NOT NULL,
    "user-experience" double precision DEFAULT 0.0 NOT NULL,
    "wg-apply" double precision DEFAULT 0.0 NOT NULL,
    "cli-pr-approver" double precision DEFAULT 0.0 NOT NULL,
    logging double precision DEFAULT 0.0 NOT NULL,
    log double precision DEFAULT 0.0 NOT NULL,
    "gcp-gcp" double precision DEFAULT 0.0 NOT NULL,
    "none" double precision DEFAULT 0.0 NOT NULL,
    "container-identity" double precision DEFAULT 0.0 NOT NULL,
    "cli-feature-matainer" double precision DEFAULT 0.0 NOT NULL,
    metrics double precision DEFAULT 0.0 NOT NULL,
    "aws-docs" double precision DEFAULT 0.0 NOT NULL,
    "node-node" double precision DEFAULT 0.0 NOT NULL,
    "resource-management" double precision DEFAULT 0.0 NOT NULL,
    "ui-pr-reviewes" double precision DEFAULT 0.0 NOT NULL,
    "contributor-experience-localhost" double precision DEFAULT 0.0 NOT NULL,
    "storage-mics" double precision DEFAULT 0.0 NOT NULL,
    "scalability-proprosals" double precision DEFAULT 0.0 NOT NULL,
    "node-docker" double precision DEFAULT 0.0 NOT NULL,
    "foo-bar" double precision DEFAULT 0.0 NOT NULL,
    etcd double precision DEFAULT 0.0 NOT NULL,
    "api-macinery" double precision DEFAULT 0.0 NOT NULL,
    "contributor-experience-help-wanted" double precision DEFAULT 0.0 NOT NULL,
    "scheduling-maintainers" double precision DEFAULT 0.0 NOT NULL,
    vmware double precision DEFAULT 0.0 NOT NULL,
    "contributor-experience-cluster-ops" double precision DEFAULT 0.0 NOT NULL,
    "area-test-infra" double precision DEFAULT 0.0 NOT NULL,
    "docs-support" double precision DEFAULT 0.0 NOT NULL,
    "on-prem" double precision DEFAULT 0.0 NOT NULL,
    security double precision DEFAULT 0.0 NOT NULL,
    bug double precision DEFAULT 0.0 NOT NULL,
    xyz double precision DEFAULT 0.0 NOT NULL,
    "api-machinery-api" double precision DEFAULT 0.0 NOT NULL,
    leads double precision DEFAULT 0.0 NOT NULL,
    "contributor-experience-storageos" double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.ssigm_txt OWNER TO gha_admin;

--
-- Name: stime_metrics; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.stime_metrics (
    "time" timestamp without time zone NOT NULL,
    series text NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    descr text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.stime_metrics OWNER TO gha_admin;

--
-- Name: suser_reviews; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.suser_reviews (
    "time" timestamp without time zone NOT NULL,
    series text NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    thockin double precision DEFAULT 0.0 NOT NULL,
    "MrHohn" double precision DEFAULT 0.0 NOT NULL,
    mikedanese double precision DEFAULT 0.0 NOT NULL,
    lavalamp double precision DEFAULT 0.0 NOT NULL,
    deads2k double precision DEFAULT 0.0 NOT NULL,
    mbohlool double precision DEFAULT 0.0 NOT NULL,
    msau42 double precision DEFAULT 0.0 NOT NULL,
    aledbf double precision DEFAULT 0.0 NOT NULL,
    dims double precision DEFAULT 0.0 NOT NULL,
    bowei double precision DEFAULT 0.0 NOT NULL,
    rramkumar1 double precision DEFAULT 0.0 NOT NULL,
    awly double precision DEFAULT 0.0 NOT NULL,
    luxas double precision DEFAULT 0.0 NOT NULL,
    jsafrane double precision DEFAULT 0.0 NOT NULL,
    stevekuznetsov double precision DEFAULT 0.0 NOT NULL,
    cblecker double precision DEFAULT 0.0 NOT NULL,
    "MaciekPytel" double precision DEFAULT 0.0 NOT NULL,
    liggitt double precision DEFAULT 0.0 NOT NULL,
    sttts double precision DEFAULT 0.0 NOT NULL,
    pwittrock double precision DEFAULT 0.0 NOT NULL,
    "MHBauer" double precision DEFAULT 0.0 NOT NULL,
    bsalamat double precision DEFAULT 0.0 NOT NULL,
    "BenTheElder" double precision DEFAULT 0.0 NOT NULL,
    "wojtek-t" double precision DEFAULT 0.0 NOT NULL,
    ixdy double precision DEFAULT 0.0 NOT NULL,
    gyliu513 double precision DEFAULT 0.0 NOT NULL,
    yue9944882 double precision DEFAULT 0.0 NOT NULL,
    janetkuo double precision DEFAULT 0.0 NOT NULL,
    roberthbailey double precision DEFAULT 0.0 NOT NULL,
    resouer double precision DEFAULT 0.0 NOT NULL,
    mengqiy double precision DEFAULT 0.0 NOT NULL,
    "DirectXMan12" double precision DEFAULT 0.0 NOT NULL,
    timothysc double precision DEFAULT 0.0 NOT NULL,
    wongma7 double precision DEFAULT 0.0 NOT NULL,
    mtaufen double precision DEFAULT 0.0 NOT NULL,
    k82cn double precision DEFAULT 0.0 NOT NULL,
    tallclair double precision DEFAULT 0.0 NOT NULL,
    "saad-ali" double precision DEFAULT 0.0 NOT NULL,
    fejta double precision DEFAULT 0.0 NOT NULL,
    nikhita double precision DEFAULT 0.0 NOT NULL,
    "aleksandra-malinowska" double precision DEFAULT 0.0 NOT NULL,
    chuckha double precision DEFAULT 0.0 NOT NULL,
    feiskyer double precision DEFAULT 0.0 NOT NULL,
    shyamjvs double precision DEFAULT 0.0 NOT NULL,
    gnufied double precision DEFAULT 0.0 NOT NULL,
    ravisantoshgudimetla double precision DEFAULT 0.0 NOT NULL,
    krzyzacy double precision DEFAULT 0.0 NOT NULL,
    neolit123 double precision DEFAULT 0.0 NOT NULL,
    justinsb double precision DEFAULT 0.0 NOT NULL,
    chenopis double precision DEFAULT 0.0 NOT NULL,
    zacharysarah double precision DEFAULT 0.0 NOT NULL,
    "Bradamant3" double precision DEFAULT 0.0 NOT NULL,
    tengqm double precision DEFAULT 0.0 NOT NULL,
    cjwagner double precision DEFAULT 0.0 NOT NULL,
    paulangton double precision DEFAULT 0.0 NOT NULL,
    carolynvs double precision DEFAULT 0.0 NOT NULL,
    spiffxp double precision DEFAULT 0.0 NOT NULL,
    monopole double precision DEFAULT 0.0 NOT NULL,
    krzysied double precision DEFAULT 0.0 NOT NULL,
    droot double precision DEFAULT 0.0 NOT NULL,
    detiber double precision DEFAULT 0.0 NOT NULL,
    mistyhacks double precision DEFAULT 0.0 NOT NULL,
    davidz627 double precision DEFAULT 0.0 NOT NULL,
    antoineco double precision DEFAULT 0.0 NOT NULL,
    "Liujingfang1" double precision DEFAULT 0.0 NOT NULL,
    rustycl0ck double precision DEFAULT 0.0 NOT NULL,
    spew double precision DEFAULT 0.0 NOT NULL,
    "xing-yang" double precision DEFAULT 0.0 NOT NULL,
    mhamilton723 double precision DEFAULT 0.0 NOT NULL,
    tpepper double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.suser_reviews OWNER TO gha_admin;

--
-- Name: swatchers; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.swatchers (
    "time" timestamp without time zone NOT NULL,
    series text NOT NULL,
    period text DEFAULT ''::text NOT NULL,
    value double precision DEFAULT 0.0 NOT NULL
);


ALTER TABLE public.swatchers OWNER TO gha_admin;

--
-- Name: tall_combined_repo_groups; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.tall_combined_repo_groups (
    "time" timestamp without time zone NOT NULL,
    all_combined_repo_group_name text,
    all_combined_repo_group_value text
);


ALTER TABLE public.tall_combined_repo_groups OWNER TO gha_admin;

--
-- Name: tall_milestones; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.tall_milestones (
    "time" timestamp without time zone NOT NULL,
    all_milestones_name text,
    all_milestones_value text
);


ALTER TABLE public.tall_milestones OWNER TO gha_admin;

--
-- Name: tall_repo_groups; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.tall_repo_groups (
    "time" timestamp without time zone NOT NULL,
    all_repo_group_name text,
    all_repo_group_value text
);


ALTER TABLE public.tall_repo_groups OWNER TO gha_admin;

--
-- Name: tall_repo_names; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.tall_repo_names (
    "time" timestamp without time zone NOT NULL,
    all_repo_names_name text,
    all_repo_names_value text
);


ALTER TABLE public.tall_repo_names OWNER TO gha_admin;

--
-- Name: tbot_commands; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.tbot_commands (
    "time" timestamp without time zone NOT NULL,
    bot_command_name text
);


ALTER TABLE public.tbot_commands OWNER TO gha_admin;

--
-- Name: tcompanies; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.tcompanies (
    "time" timestamp without time zone NOT NULL,
    companies_name text
);


ALTER TABLE public.tcompanies OWNER TO gha_admin;

--
-- Name: tpr_labels_tags; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.tpr_labels_tags (
    "time" timestamp without time zone NOT NULL,
    pr_labels_tags_value text,
    pr_labels_tags_name text
);


ALTER TABLE public.tpr_labels_tags OWNER TO gha_admin;

--
-- Name: tpriority_labels_with_all; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.tpriority_labels_with_all (
    "time" timestamp without time zone NOT NULL,
    priority_labels_value_with_all text,
    priority_labels_name_with_all text
);


ALTER TABLE public.tpriority_labels_with_all OWNER TO gha_admin;

--
-- Name: tquick_ranges; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.tquick_ranges (
    "time" timestamp without time zone NOT NULL,
    quick_ranges_name text,
    quick_ranges_data text,
    quick_ranges_suffix text
);


ALTER TABLE public.tquick_ranges OWNER TO gha_admin;

--
-- Name: trepo_groups; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.trepo_groups (
    "time" timestamp without time zone NOT NULL,
    repo_group_name text,
    repo_group_value text
);


ALTER TABLE public.trepo_groups OWNER TO gha_admin;

--
-- Name: treviewers; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.treviewers (
    "time" timestamp without time zone NOT NULL,
    reviewers_name text
);


ALTER TABLE public.treviewers OWNER TO gha_admin;

--
-- Name: tsig_mentions_labels; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.tsig_mentions_labels (
    "time" timestamp without time zone NOT NULL,
    sig_mentions_labels_value text,
    sig_mentions_labels_name text
);


ALTER TABLE public.tsig_mentions_labels OWNER TO gha_admin;

--
-- Name: tsig_mentions_labels_with_all; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.tsig_mentions_labels_with_all (
    "time" timestamp without time zone NOT NULL,
    sig_mentions_labels_name_with_all text,
    sig_mentions_labels_value_with_all text
);


ALTER TABLE public.tsig_mentions_labels_with_all OWNER TO gha_admin;

--
-- Name: tsig_mentions_texts; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.tsig_mentions_texts (
    "time" timestamp without time zone NOT NULL,
    sig_mentions_texts_name text,
    sig_mentions_texts_value text
);


ALTER TABLE public.tsig_mentions_texts OWNER TO gha_admin;

--
-- Name: tsigm_lbl_kinds; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.tsigm_lbl_kinds (
    "time" timestamp without time zone NOT NULL,
    sigm_lbl_kind_name text,
    sigm_lbl_kind_value text
);


ALTER TABLE public.tsigm_lbl_kinds OWNER TO gha_admin;

--
-- Name: tsigm_lbl_kinds_with_all; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.tsigm_lbl_kinds_with_all (
    "time" timestamp without time zone NOT NULL,
    sigm_lbl_kind_name_with_all text,
    sigm_lbl_kind_value_with_all text
);


ALTER TABLE public.tsigm_lbl_kinds_with_all OWNER TO gha_admin;

--
-- Name: tsize_labels_with_all; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.tsize_labels_with_all (
    "time" timestamp without time zone NOT NULL,
    size_labels_name_with_all text,
    size_labels_value_with_all text
);


ALTER TABLE public.tsize_labels_with_all OWNER TO gha_admin;

--
-- Name: ttop_repo_names; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.ttop_repo_names (
    "time" timestamp without time zone NOT NULL,
    top_repo_names_value text,
    top_repo_names_name text
);


ALTER TABLE public.ttop_repo_names OWNER TO gha_admin;

--
-- Name: ttop_repo_names_with_all; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.ttop_repo_names_with_all (
    "time" timestamp without time zone NOT NULL,
    top_repo_names_name_with_all text,
    top_repo_names_value_with_all text
);


ALTER TABLE public.ttop_repo_names_with_all OWNER TO gha_admin;

--
-- Name: ttop_repos_with_all; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.ttop_repos_with_all (
    "time" timestamp without time zone NOT NULL,
    top_repos_name_with_all text,
    top_repos_value_with_all text
);


ALTER TABLE public.ttop_repos_with_all OWNER TO gha_admin;

--
-- Name: tusers; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE public.tusers (
    "time" timestamp without time zone NOT NULL,
    users_name text
);


ALTER TABLE public.tusers OWNER TO gha_admin;

--
-- Name: gha_logs id; Type: DEFAULT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_logs ALTER COLUMN id SET DEFAULT nextval('public.gha_logs_id_seq'::regclass);


--
-- Name: gha_actors_affiliations gha_actors_affiliations_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_actors_affiliations
    ADD CONSTRAINT gha_actors_affiliations_pkey PRIMARY KEY (actor_id, company_name, dt_from, dt_to);


--
-- Name: gha_actors_emails gha_actors_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_actors_emails
    ADD CONSTRAINT gha_actors_emails_pkey PRIMARY KEY (actor_id, email);


--
-- Name: gha_actors gha_actors_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_actors
    ADD CONSTRAINT gha_actors_pkey PRIMARY KEY (id);


--
-- Name: gha_assets gha_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_assets
    ADD CONSTRAINT gha_assets_pkey PRIMARY KEY (id, event_id);


--
-- Name: gha_branches gha_branches_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_branches
    ADD CONSTRAINT gha_branches_pkey PRIMARY KEY (sha, event_id);


--
-- Name: gha_comments gha_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_comments
    ADD CONSTRAINT gha_comments_pkey PRIMARY KEY (id, event_id);


--
-- Name: gha_commits_files gha_commits_files_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_commits_files
    ADD CONSTRAINT gha_commits_files_pkey PRIMARY KEY (sha, path);


--
-- Name: gha_commits gha_commits_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_commits
    ADD CONSTRAINT gha_commits_pkey PRIMARY KEY (sha, event_id);


--
-- Name: gha_companies gha_companies_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_companies
    ADD CONSTRAINT gha_companies_pkey PRIMARY KEY (name);


--
-- Name: gha_computed gha_computed_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_computed
    ADD CONSTRAINT gha_computed_pkey PRIMARY KEY (metric, dt);


--
-- Name: gha_events_commits_files gha_events_commits_files_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_events_commits_files
    ADD CONSTRAINT gha_events_commits_files_pkey PRIMARY KEY (sha, event_id, path);


--
-- Name: gha_events gha_events_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_events
    ADD CONSTRAINT gha_events_pkey PRIMARY KEY (id);


--
-- Name: gha_forkees gha_forkees_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_forkees
    ADD CONSTRAINT gha_forkees_pkey PRIMARY KEY (id, event_id);


--
-- Name: gha_issues_assignees gha_issues_assignees_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_issues_assignees
    ADD CONSTRAINT gha_issues_assignees_pkey PRIMARY KEY (issue_id, event_id, assignee_id);


--
-- Name: gha_issues_events_labels gha_issues_events_labels_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_issues_events_labels
    ADD CONSTRAINT gha_issues_events_labels_pkey PRIMARY KEY (issue_id, event_id, label_id);


--
-- Name: gha_issues_labels gha_issues_labels_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_issues_labels
    ADD CONSTRAINT gha_issues_labels_pkey PRIMARY KEY (issue_id, event_id, label_id);


--
-- Name: gha_issues gha_issues_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_issues
    ADD CONSTRAINT gha_issues_pkey PRIMARY KEY (id, event_id);


--
-- Name: gha_labels gha_labels_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_labels
    ADD CONSTRAINT gha_labels_pkey PRIMARY KEY (id);


--
-- Name: gha_milestones gha_milestones_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_milestones
    ADD CONSTRAINT gha_milestones_pkey PRIMARY KEY (id, event_id);


--
-- Name: gha_orgs gha_orgs_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_orgs
    ADD CONSTRAINT gha_orgs_pkey PRIMARY KEY (id);


--
-- Name: gha_pages gha_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_pages
    ADD CONSTRAINT gha_pages_pkey PRIMARY KEY (sha, event_id, action, title);


--
-- Name: gha_parsed gha_parsed_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_parsed
    ADD CONSTRAINT gha_parsed_pkey PRIMARY KEY (dt);


--
-- Name: gha_payloads gha_payloads_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_payloads
    ADD CONSTRAINT gha_payloads_pkey PRIMARY KEY (event_id);


--
-- Name: gha_postprocess_scripts gha_postprocess_scripts_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_postprocess_scripts
    ADD CONSTRAINT gha_postprocess_scripts_pkey PRIMARY KEY (ord, path);


--
-- Name: gha_pull_requests_assignees gha_pull_requests_assignees_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_pull_requests_assignees
    ADD CONSTRAINT gha_pull_requests_assignees_pkey PRIMARY KEY (pull_request_id, event_id, assignee_id);


--
-- Name: gha_pull_requests gha_pull_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_pull_requests
    ADD CONSTRAINT gha_pull_requests_pkey PRIMARY KEY (id, event_id);


--
-- Name: gha_pull_requests_requested_reviewers gha_pull_requests_requested_reviewers_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_pull_requests_requested_reviewers
    ADD CONSTRAINT gha_pull_requests_requested_reviewers_pkey PRIMARY KEY (pull_request_id, event_id, requested_reviewer_id);


--
-- Name: gha_releases_assets gha_releases_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_releases_assets
    ADD CONSTRAINT gha_releases_assets_pkey PRIMARY KEY (release_id, event_id, asset_id);


--
-- Name: gha_releases gha_releases_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_releases
    ADD CONSTRAINT gha_releases_pkey PRIMARY KEY (id, event_id);


--
-- Name: gha_repos gha_repos_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_repos
    ADD CONSTRAINT gha_repos_pkey PRIMARY KEY (id, name);


--
-- Name: gha_skip_commits gha_skip_commits_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_skip_commits
    ADD CONSTRAINT gha_skip_commits_pkey PRIMARY KEY (sha);


--
-- Name: gha_teams gha_teams_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_teams
    ADD CONSTRAINT gha_teams_pkey PRIMARY KEY (id, event_id);


--
-- Name: gha_teams_repositories gha_teams_repositories_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_teams_repositories
    ADD CONSTRAINT gha_teams_repositories_pkey PRIMARY KEY (team_id, event_id, repository_id);


--
-- Name: gha_vars gha_vars_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.gha_vars
    ADD CONSTRAINT gha_vars_pkey PRIMARY KEY (name);


--
-- Name: sannotations sannotations_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.sannotations
    ADD CONSTRAINT sannotations_pkey PRIMARY KEY ("time", period);


--
-- Name: sbot_commands sbot_commands_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.sbot_commands
    ADD CONSTRAINT sbot_commands_pkey PRIMARY KEY ("time", series, period);


--
-- Name: scompany_activity scompany_activity_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.scompany_activity
    ADD CONSTRAINT scompany_activity_pkey PRIMARY KEY ("time", series, period);


--
-- Name: sepisodic_contributors sepisodic_contributors_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.sepisodic_contributors
    ADD CONSTRAINT sepisodic_contributors_pkey PRIMARY KEY ("time", series, period);


--
-- Name: sepisodic_issues sepisodic_issues_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.sepisodic_issues
    ADD CONSTRAINT sepisodic_issues_pkey PRIMARY KEY ("time", series, period);


--
-- Name: sevents_h sevents_h_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.sevents_h
    ADD CONSTRAINT sevents_h_pkey PRIMARY KEY ("time", period);


--
-- Name: sfirst_non_author sfirst_non_author_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.sfirst_non_author
    ADD CONSTRAINT sfirst_non_author_pkey PRIMARY KEY ("time", series, period);


--
-- Name: sgh_stats_r sgh_stats_r_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.sgh_stats_r
    ADD CONSTRAINT sgh_stats_r_pkey PRIMARY KEY ("time", series, period);


--
-- Name: sgh_stats_rgrp sgh_stats_rgrp_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.sgh_stats_rgrp
    ADD CONSTRAINT sgh_stats_rgrp_pkey PRIMARY KEY ("time", series, period);


--
-- Name: shcomcommenters shcomcommenters_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shcomcommenters
    ADD CONSTRAINT shcomcommenters_pkey PRIMARY KEY ("time", period);


--
-- Name: shcomcomments shcomcomments_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shcomcomments
    ADD CONSTRAINT shcomcomments_pkey PRIMARY KEY ("time", period);


--
-- Name: shcomcommitcommenters shcomcommitcommenters_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shcomcommitcommenters
    ADD CONSTRAINT shcomcommitcommenters_pkey PRIMARY KEY ("time", period);


--
-- Name: shcomcommits shcomcommits_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shcomcommits
    ADD CONSTRAINT shcomcommits_pkey PRIMARY KEY ("time", period);


--
-- Name: shcomcommitters shcomcommitters_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shcomcommitters
    ADD CONSTRAINT shcomcommitters_pkey PRIMARY KEY ("time", period);


--
-- Name: shcomcontributions shcomcontributions_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shcomcontributions
    ADD CONSTRAINT shcomcontributions_pkey PRIMARY KEY ("time", period);


--
-- Name: shcomcontributors shcomcontributors_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shcomcontributors
    ADD CONSTRAINT shcomcontributors_pkey PRIMARY KEY ("time", period);


--
-- Name: shcomevents shcomevents_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shcomevents
    ADD CONSTRAINT shcomevents_pkey PRIMARY KEY ("time", period);


--
-- Name: shcomforkers shcomforkers_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shcomforkers
    ADD CONSTRAINT shcomforkers_pkey PRIMARY KEY ("time", period);


--
-- Name: shcomissuecommenters shcomissuecommenters_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shcomissuecommenters
    ADD CONSTRAINT shcomissuecommenters_pkey PRIMARY KEY ("time", period);


--
-- Name: shcomissuecreators shcomissuecreators_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shcomissuecreators
    ADD CONSTRAINT shcomissuecreators_pkey PRIMARY KEY ("time", period);


--
-- Name: shcomissues shcomissues_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shcomissues
    ADD CONSTRAINT shcomissues_pkey PRIMARY KEY ("time", period);


--
-- Name: shcomprcreators shcomprcreators_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shcomprcreators
    ADD CONSTRAINT shcomprcreators_pkey PRIMARY KEY ("time", period);


--
-- Name: shcomprreviewers shcomprreviewers_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shcomprreviewers
    ADD CONSTRAINT shcomprreviewers_pkey PRIMARY KEY ("time", period);


--
-- Name: shcomprs shcomprs_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shcomprs
    ADD CONSTRAINT shcomprs_pkey PRIMARY KEY ("time", period);


--
-- Name: shcomrepositories shcomrepositories_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shcomrepositories
    ADD CONSTRAINT shcomrepositories_pkey PRIMARY KEY ("time", period);


--
-- Name: shcomwatchers shcomwatchers_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shcomwatchers
    ADD CONSTRAINT shcomwatchers_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_active_reposall shdev_active_reposall_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_active_reposall
    ADD CONSTRAINT shdev_active_reposall_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_active_reposapimachinery shdev_active_reposapimachinery_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_active_reposapimachinery
    ADD CONSTRAINT shdev_active_reposapimachinery_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_active_reposapps shdev_active_reposapps_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_active_reposapps
    ADD CONSTRAINT shdev_active_reposapps_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_active_reposautoscalingandmonitoring shdev_active_reposautoscalingandmonitoring_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_active_reposautoscalingandmonitoring
    ADD CONSTRAINT shdev_active_reposautoscalingandmonitoring_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_active_reposclients shdev_active_reposclients_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_active_reposclients
    ADD CONSTRAINT shdev_active_reposclients_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_active_reposclusterlifecycle shdev_active_reposclusterlifecycle_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_active_reposclusterlifecycle
    ADD CONSTRAINT shdev_active_reposclusterlifecycle_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_active_reposcsi shdev_active_reposcsi_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_active_reposcsi
    ADD CONSTRAINT shdev_active_reposcsi_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_active_reposdocs shdev_active_reposdocs_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_active_reposdocs
    ADD CONSTRAINT shdev_active_reposdocs_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_active_reposkubernetes shdev_active_reposkubernetes_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_active_reposkubernetes
    ADD CONSTRAINT shdev_active_reposkubernetes_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_active_reposmisc shdev_active_reposmisc_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_active_reposmisc
    ADD CONSTRAINT shdev_active_reposmisc_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_active_reposnetworking shdev_active_reposnetworking_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_active_reposnetworking
    ADD CONSTRAINT shdev_active_reposnetworking_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_active_reposnode shdev_active_reposnode_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_active_reposnode
    ADD CONSTRAINT shdev_active_reposnode_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_active_reposproject shdev_active_reposproject_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_active_reposproject
    ADD CONSTRAINT shdev_active_reposproject_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_active_reposprojectinfra shdev_active_reposprojectinfra_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_active_reposprojectinfra
    ADD CONSTRAINT shdev_active_reposprojectinfra_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_active_reposstorage shdev_active_reposstorage_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_active_reposstorage
    ADD CONSTRAINT shdev_active_reposstorage_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_active_reposui shdev_active_reposui_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_active_reposui
    ADD CONSTRAINT shdev_active_reposui_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_approvesall shdev_approvesall_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_approvesall
    ADD CONSTRAINT shdev_approvesall_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_approvesapimachinery shdev_approvesapimachinery_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_approvesapimachinery
    ADD CONSTRAINT shdev_approvesapimachinery_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_approvesapps shdev_approvesapps_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_approvesapps
    ADD CONSTRAINT shdev_approvesapps_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_approvesautoscalingandmonitoring shdev_approvesautoscalingandmonitoring_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_approvesautoscalingandmonitoring
    ADD CONSTRAINT shdev_approvesautoscalingandmonitoring_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_approvesclients shdev_approvesclients_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_approvesclients
    ADD CONSTRAINT shdev_approvesclients_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_approvesclusterlifecycle shdev_approvesclusterlifecycle_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_approvesclusterlifecycle
    ADD CONSTRAINT shdev_approvesclusterlifecycle_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_approvescontrib shdev_approvescontrib_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_approvescontrib
    ADD CONSTRAINT shdev_approvescontrib_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_approvescsi shdev_approvescsi_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_approvescsi
    ADD CONSTRAINT shdev_approvescsi_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_approvesdocs shdev_approvesdocs_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_approvesdocs
    ADD CONSTRAINT shdev_approvesdocs_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_approveskubernetes shdev_approveskubernetes_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_approveskubernetes
    ADD CONSTRAINT shdev_approveskubernetes_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_approvesmisc shdev_approvesmisc_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_approvesmisc
    ADD CONSTRAINT shdev_approvesmisc_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_approvesmulticluster shdev_approvesmulticluster_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_approvesmulticluster
    ADD CONSTRAINT shdev_approvesmulticluster_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_approvesnetworking shdev_approvesnetworking_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_approvesnetworking
    ADD CONSTRAINT shdev_approvesnetworking_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_approvesnode shdev_approvesnode_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_approvesnode
    ADD CONSTRAINT shdev_approvesnode_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_approvesproject shdev_approvesproject_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_approvesproject
    ADD CONSTRAINT shdev_approvesproject_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_approvesprojectinfra shdev_approvesprojectinfra_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_approvesprojectinfra
    ADD CONSTRAINT shdev_approvesprojectinfra_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_approvessigservicecatalog shdev_approvessigservicecatalog_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_approvessigservicecatalog
    ADD CONSTRAINT shdev_approvessigservicecatalog_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_approvesstorage shdev_approvesstorage_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_approvesstorage
    ADD CONSTRAINT shdev_approvesstorage_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_approvesui shdev_approvesui_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_approvesui
    ADD CONSTRAINT shdev_approvesui_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commentsall shdev_commentsall_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commentsall
    ADD CONSTRAINT shdev_commentsall_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commentsapimachinery shdev_commentsapimachinery_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commentsapimachinery
    ADD CONSTRAINT shdev_commentsapimachinery_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commentsapps shdev_commentsapps_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commentsapps
    ADD CONSTRAINT shdev_commentsapps_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commentsautoscalingandmonitoring shdev_commentsautoscalingandmonitoring_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commentsautoscalingandmonitoring
    ADD CONSTRAINT shdev_commentsautoscalingandmonitoring_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commentsclients shdev_commentsclients_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commentsclients
    ADD CONSTRAINT shdev_commentsclients_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commentsclusterlifecycle shdev_commentsclusterlifecycle_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commentsclusterlifecycle
    ADD CONSTRAINT shdev_commentsclusterlifecycle_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commentscontrib shdev_commentscontrib_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commentscontrib
    ADD CONSTRAINT shdev_commentscontrib_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commentscsi shdev_commentscsi_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commentscsi
    ADD CONSTRAINT shdev_commentscsi_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commentsdocs shdev_commentsdocs_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commentsdocs
    ADD CONSTRAINT shdev_commentsdocs_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commentskubernetes shdev_commentskubernetes_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commentskubernetes
    ADD CONSTRAINT shdev_commentskubernetes_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commentsmisc shdev_commentsmisc_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commentsmisc
    ADD CONSTRAINT shdev_commentsmisc_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commentsmulticluster shdev_commentsmulticluster_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commentsmulticluster
    ADD CONSTRAINT shdev_commentsmulticluster_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commentsnetworking shdev_commentsnetworking_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commentsnetworking
    ADD CONSTRAINT shdev_commentsnetworking_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commentsnode shdev_commentsnode_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commentsnode
    ADD CONSTRAINT shdev_commentsnode_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commentsproject shdev_commentsproject_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commentsproject
    ADD CONSTRAINT shdev_commentsproject_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commentsprojectinfra shdev_commentsprojectinfra_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commentsprojectinfra
    ADD CONSTRAINT shdev_commentsprojectinfra_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commentssigservicecatalog shdev_commentssigservicecatalog_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commentssigservicecatalog
    ADD CONSTRAINT shdev_commentssigservicecatalog_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commentsstorage shdev_commentsstorage_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commentsstorage
    ADD CONSTRAINT shdev_commentsstorage_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commentsui shdev_commentsui_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commentsui
    ADD CONSTRAINT shdev_commentsui_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commit_commentsall shdev_commit_commentsall_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commit_commentsall
    ADD CONSTRAINT shdev_commit_commentsall_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commit_commentsapps shdev_commit_commentsapps_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commit_commentsapps
    ADD CONSTRAINT shdev_commit_commentsapps_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commit_commentsautoscalingandmonitoring shdev_commit_commentsautoscalingandmonitoring_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commit_commentsautoscalingandmonitoring
    ADD CONSTRAINT shdev_commit_commentsautoscalingandmonitoring_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commit_commentsclients shdev_commit_commentsclients_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commit_commentsclients
    ADD CONSTRAINT shdev_commit_commentsclients_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commit_commentsclusterlifecycle shdev_commit_commentsclusterlifecycle_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commit_commentsclusterlifecycle
    ADD CONSTRAINT shdev_commit_commentsclusterlifecycle_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commit_commentscontrib shdev_commit_commentscontrib_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commit_commentscontrib
    ADD CONSTRAINT shdev_commit_commentscontrib_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commit_commentscsi shdev_commit_commentscsi_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commit_commentscsi
    ADD CONSTRAINT shdev_commit_commentscsi_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commit_commentsdocs shdev_commit_commentsdocs_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commit_commentsdocs
    ADD CONSTRAINT shdev_commit_commentsdocs_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commit_commentskubernetes shdev_commit_commentskubernetes_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commit_commentskubernetes
    ADD CONSTRAINT shdev_commit_commentskubernetes_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commit_commentsmisc shdev_commit_commentsmisc_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commit_commentsmisc
    ADD CONSTRAINT shdev_commit_commentsmisc_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commit_commentsnetworking shdev_commit_commentsnetworking_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commit_commentsnetworking
    ADD CONSTRAINT shdev_commit_commentsnetworking_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commit_commentsnode shdev_commit_commentsnode_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commit_commentsnode
    ADD CONSTRAINT shdev_commit_commentsnode_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commit_commentsproject shdev_commit_commentsproject_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commit_commentsproject
    ADD CONSTRAINT shdev_commit_commentsproject_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commit_commentsprojectinfra shdev_commit_commentsprojectinfra_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commit_commentsprojectinfra
    ADD CONSTRAINT shdev_commit_commentsprojectinfra_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commit_commentssigservicecatalog shdev_commit_commentssigservicecatalog_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commit_commentssigservicecatalog
    ADD CONSTRAINT shdev_commit_commentssigservicecatalog_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commit_commentsstorage shdev_commit_commentsstorage_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commit_commentsstorage
    ADD CONSTRAINT shdev_commit_commentsstorage_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commit_commentsui shdev_commit_commentsui_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commit_commentsui
    ADD CONSTRAINT shdev_commit_commentsui_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commitsall shdev_commitsall_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commitsall
    ADD CONSTRAINT shdev_commitsall_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commitsapimachinery shdev_commitsapimachinery_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commitsapimachinery
    ADD CONSTRAINT shdev_commitsapimachinery_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commitsapps shdev_commitsapps_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commitsapps
    ADD CONSTRAINT shdev_commitsapps_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commitsautoscalingandmonitoring shdev_commitsautoscalingandmonitoring_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commitsautoscalingandmonitoring
    ADD CONSTRAINT shdev_commitsautoscalingandmonitoring_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commitsclients shdev_commitsclients_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commitsclients
    ADD CONSTRAINT shdev_commitsclients_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commitsclusterlifecycle shdev_commitsclusterlifecycle_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commitsclusterlifecycle
    ADD CONSTRAINT shdev_commitsclusterlifecycle_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commitscontrib shdev_commitscontrib_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commitscontrib
    ADD CONSTRAINT shdev_commitscontrib_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commitscsi shdev_commitscsi_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commitscsi
    ADD CONSTRAINT shdev_commitscsi_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commitsdocs shdev_commitsdocs_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commitsdocs
    ADD CONSTRAINT shdev_commitsdocs_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commitskubernetes shdev_commitskubernetes_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commitskubernetes
    ADD CONSTRAINT shdev_commitskubernetes_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commitsmisc shdev_commitsmisc_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commitsmisc
    ADD CONSTRAINT shdev_commitsmisc_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commitsmulticluster shdev_commitsmulticluster_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commitsmulticluster
    ADD CONSTRAINT shdev_commitsmulticluster_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commitsnetworking shdev_commitsnetworking_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commitsnetworking
    ADD CONSTRAINT shdev_commitsnetworking_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commitsnode shdev_commitsnode_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commitsnode
    ADD CONSTRAINT shdev_commitsnode_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commitsproject shdev_commitsproject_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commitsproject
    ADD CONSTRAINT shdev_commitsproject_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commitsprojectinfra shdev_commitsprojectinfra_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commitsprojectinfra
    ADD CONSTRAINT shdev_commitsprojectinfra_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commitssigservicecatalog shdev_commitssigservicecatalog_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commitssigservicecatalog
    ADD CONSTRAINT shdev_commitssigservicecatalog_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commitsstorage shdev_commitsstorage_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commitsstorage
    ADD CONSTRAINT shdev_commitsstorage_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_commitsui shdev_commitsui_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_commitsui
    ADD CONSTRAINT shdev_commitsui_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_contributionsall shdev_contributionsall_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_contributionsall
    ADD CONSTRAINT shdev_contributionsall_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_contributionsapimachinery shdev_contributionsapimachinery_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_contributionsapimachinery
    ADD CONSTRAINT shdev_contributionsapimachinery_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_contributionsapps shdev_contributionsapps_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_contributionsapps
    ADD CONSTRAINT shdev_contributionsapps_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_contributionsautoscalingandmonitoring shdev_contributionsautoscalingandmonitoring_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_contributionsautoscalingandmonitoring
    ADD CONSTRAINT shdev_contributionsautoscalingandmonitoring_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_contributionsclients shdev_contributionsclients_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_contributionsclients
    ADD CONSTRAINT shdev_contributionsclients_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_contributionsclusterlifecycle shdev_contributionsclusterlifecycle_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_contributionsclusterlifecycle
    ADD CONSTRAINT shdev_contributionsclusterlifecycle_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_contributionscontrib shdev_contributionscontrib_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_contributionscontrib
    ADD CONSTRAINT shdev_contributionscontrib_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_contributionscsi shdev_contributionscsi_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_contributionscsi
    ADD CONSTRAINT shdev_contributionscsi_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_contributionsdocs shdev_contributionsdocs_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_contributionsdocs
    ADD CONSTRAINT shdev_contributionsdocs_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_contributionskubernetes shdev_contributionskubernetes_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_contributionskubernetes
    ADD CONSTRAINT shdev_contributionskubernetes_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_contributionsmisc shdev_contributionsmisc_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_contributionsmisc
    ADD CONSTRAINT shdev_contributionsmisc_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_contributionsmulticluster shdev_contributionsmulticluster_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_contributionsmulticluster
    ADD CONSTRAINT shdev_contributionsmulticluster_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_contributionsnetworking shdev_contributionsnetworking_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_contributionsnetworking
    ADD CONSTRAINT shdev_contributionsnetworking_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_contributionsnode shdev_contributionsnode_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_contributionsnode
    ADD CONSTRAINT shdev_contributionsnode_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_contributionsproject shdev_contributionsproject_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_contributionsproject
    ADD CONSTRAINT shdev_contributionsproject_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_contributionsprojectinfra shdev_contributionsprojectinfra_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_contributionsprojectinfra
    ADD CONSTRAINT shdev_contributionsprojectinfra_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_contributionssigservicecatalog shdev_contributionssigservicecatalog_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_contributionssigservicecatalog
    ADD CONSTRAINT shdev_contributionssigservicecatalog_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_contributionsstorage shdev_contributionsstorage_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_contributionsstorage
    ADD CONSTRAINT shdev_contributionsstorage_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_contributionsui shdev_contributionsui_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_contributionsui
    ADD CONSTRAINT shdev_contributionsui_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_eventsall shdev_eventsall_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_eventsall
    ADD CONSTRAINT shdev_eventsall_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_eventsapimachinery shdev_eventsapimachinery_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_eventsapimachinery
    ADD CONSTRAINT shdev_eventsapimachinery_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_eventsapps shdev_eventsapps_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_eventsapps
    ADD CONSTRAINT shdev_eventsapps_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_eventsautoscalingandmonitoring shdev_eventsautoscalingandmonitoring_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_eventsautoscalingandmonitoring
    ADD CONSTRAINT shdev_eventsautoscalingandmonitoring_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_eventsclients shdev_eventsclients_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_eventsclients
    ADD CONSTRAINT shdev_eventsclients_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_eventsclusterlifecycle shdev_eventsclusterlifecycle_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_eventsclusterlifecycle
    ADD CONSTRAINT shdev_eventsclusterlifecycle_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_eventscontrib shdev_eventscontrib_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_eventscontrib
    ADD CONSTRAINT shdev_eventscontrib_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_eventscsi shdev_eventscsi_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_eventscsi
    ADD CONSTRAINT shdev_eventscsi_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_eventsdocs shdev_eventsdocs_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_eventsdocs
    ADD CONSTRAINT shdev_eventsdocs_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_eventskubernetes shdev_eventskubernetes_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_eventskubernetes
    ADD CONSTRAINT shdev_eventskubernetes_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_eventsmisc shdev_eventsmisc_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_eventsmisc
    ADD CONSTRAINT shdev_eventsmisc_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_eventsmulticluster shdev_eventsmulticluster_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_eventsmulticluster
    ADD CONSTRAINT shdev_eventsmulticluster_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_eventsnetworking shdev_eventsnetworking_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_eventsnetworking
    ADD CONSTRAINT shdev_eventsnetworking_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_eventsnode shdev_eventsnode_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_eventsnode
    ADD CONSTRAINT shdev_eventsnode_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_eventsproject shdev_eventsproject_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_eventsproject
    ADD CONSTRAINT shdev_eventsproject_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_eventsprojectinfra shdev_eventsprojectinfra_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_eventsprojectinfra
    ADD CONSTRAINT shdev_eventsprojectinfra_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_eventssigservicecatalog shdev_eventssigservicecatalog_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_eventssigservicecatalog
    ADD CONSTRAINT shdev_eventssigservicecatalog_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_eventsstorage shdev_eventsstorage_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_eventsstorage
    ADD CONSTRAINT shdev_eventsstorage_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_eventsui shdev_eventsui_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_eventsui
    ADD CONSTRAINT shdev_eventsui_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issue_commentsall shdev_issue_commentsall_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issue_commentsall
    ADD CONSTRAINT shdev_issue_commentsall_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issue_commentsapimachinery shdev_issue_commentsapimachinery_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issue_commentsapimachinery
    ADD CONSTRAINT shdev_issue_commentsapimachinery_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issue_commentsapps shdev_issue_commentsapps_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issue_commentsapps
    ADD CONSTRAINT shdev_issue_commentsapps_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issue_commentsautoscalingandmonitoring shdev_issue_commentsautoscalingandmonitoring_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issue_commentsautoscalingandmonitoring
    ADD CONSTRAINT shdev_issue_commentsautoscalingandmonitoring_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issue_commentsclients shdev_issue_commentsclients_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issue_commentsclients
    ADD CONSTRAINT shdev_issue_commentsclients_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issue_commentsclusterlifecycle shdev_issue_commentsclusterlifecycle_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issue_commentsclusterlifecycle
    ADD CONSTRAINT shdev_issue_commentsclusterlifecycle_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issue_commentscontrib shdev_issue_commentscontrib_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issue_commentscontrib
    ADD CONSTRAINT shdev_issue_commentscontrib_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issue_commentscsi shdev_issue_commentscsi_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issue_commentscsi
    ADD CONSTRAINT shdev_issue_commentscsi_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issue_commentsdocs shdev_issue_commentsdocs_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issue_commentsdocs
    ADD CONSTRAINT shdev_issue_commentsdocs_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issue_commentskubernetes shdev_issue_commentskubernetes_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issue_commentskubernetes
    ADD CONSTRAINT shdev_issue_commentskubernetes_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issue_commentsmisc shdev_issue_commentsmisc_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issue_commentsmisc
    ADD CONSTRAINT shdev_issue_commentsmisc_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issue_commentsmulticluster shdev_issue_commentsmulticluster_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issue_commentsmulticluster
    ADD CONSTRAINT shdev_issue_commentsmulticluster_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issue_commentsnetworking shdev_issue_commentsnetworking_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issue_commentsnetworking
    ADD CONSTRAINT shdev_issue_commentsnetworking_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issue_commentsnode shdev_issue_commentsnode_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issue_commentsnode
    ADD CONSTRAINT shdev_issue_commentsnode_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issue_commentsproject shdev_issue_commentsproject_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issue_commentsproject
    ADD CONSTRAINT shdev_issue_commentsproject_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issue_commentsprojectinfra shdev_issue_commentsprojectinfra_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issue_commentsprojectinfra
    ADD CONSTRAINT shdev_issue_commentsprojectinfra_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issue_commentssigservicecatalog shdev_issue_commentssigservicecatalog_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issue_commentssigservicecatalog
    ADD CONSTRAINT shdev_issue_commentssigservicecatalog_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issue_commentsstorage shdev_issue_commentsstorage_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issue_commentsstorage
    ADD CONSTRAINT shdev_issue_commentsstorage_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issue_commentsui shdev_issue_commentsui_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issue_commentsui
    ADD CONSTRAINT shdev_issue_commentsui_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issuesall shdev_issuesall_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issuesall
    ADD CONSTRAINT shdev_issuesall_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issuesapimachinery shdev_issuesapimachinery_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issuesapimachinery
    ADD CONSTRAINT shdev_issuesapimachinery_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issuesapps shdev_issuesapps_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issuesapps
    ADD CONSTRAINT shdev_issuesapps_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issuesautoscalingandmonitoring shdev_issuesautoscalingandmonitoring_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issuesautoscalingandmonitoring
    ADD CONSTRAINT shdev_issuesautoscalingandmonitoring_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issuesclients shdev_issuesclients_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issuesclients
    ADD CONSTRAINT shdev_issuesclients_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issuesclusterlifecycle shdev_issuesclusterlifecycle_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issuesclusterlifecycle
    ADD CONSTRAINT shdev_issuesclusterlifecycle_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issuescontrib shdev_issuescontrib_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issuescontrib
    ADD CONSTRAINT shdev_issuescontrib_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issuescsi shdev_issuescsi_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issuescsi
    ADD CONSTRAINT shdev_issuescsi_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issuesdocs shdev_issuesdocs_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issuesdocs
    ADD CONSTRAINT shdev_issuesdocs_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issueskubernetes shdev_issueskubernetes_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issueskubernetes
    ADD CONSTRAINT shdev_issueskubernetes_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issuesmisc shdev_issuesmisc_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issuesmisc
    ADD CONSTRAINT shdev_issuesmisc_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issuesmulticluster shdev_issuesmulticluster_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issuesmulticluster
    ADD CONSTRAINT shdev_issuesmulticluster_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issuesnetworking shdev_issuesnetworking_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issuesnetworking
    ADD CONSTRAINT shdev_issuesnetworking_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issuesnode shdev_issuesnode_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issuesnode
    ADD CONSTRAINT shdev_issuesnode_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issuesproject shdev_issuesproject_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issuesproject
    ADD CONSTRAINT shdev_issuesproject_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issuesprojectinfra shdev_issuesprojectinfra_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issuesprojectinfra
    ADD CONSTRAINT shdev_issuesprojectinfra_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issuessigservicecatalog shdev_issuessigservicecatalog_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issuessigservicecatalog
    ADD CONSTRAINT shdev_issuessigservicecatalog_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issuesstorage shdev_issuesstorage_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issuesstorage
    ADD CONSTRAINT shdev_issuesstorage_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_issuesui shdev_issuesui_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_issuesui
    ADD CONSTRAINT shdev_issuesui_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_prsall shdev_prsall_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_prsall
    ADD CONSTRAINT shdev_prsall_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_prsapimachinery shdev_prsapimachinery_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_prsapimachinery
    ADD CONSTRAINT shdev_prsapimachinery_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_prsapps shdev_prsapps_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_prsapps
    ADD CONSTRAINT shdev_prsapps_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_prsautoscalingandmonitoring shdev_prsautoscalingandmonitoring_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_prsautoscalingandmonitoring
    ADD CONSTRAINT shdev_prsautoscalingandmonitoring_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_prsclients shdev_prsclients_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_prsclients
    ADD CONSTRAINT shdev_prsclients_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_prsclusterlifecycle shdev_prsclusterlifecycle_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_prsclusterlifecycle
    ADD CONSTRAINT shdev_prsclusterlifecycle_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_prscontrib shdev_prscontrib_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_prscontrib
    ADD CONSTRAINT shdev_prscontrib_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_prscsi shdev_prscsi_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_prscsi
    ADD CONSTRAINT shdev_prscsi_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_prsdocs shdev_prsdocs_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_prsdocs
    ADD CONSTRAINT shdev_prsdocs_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_prskubernetes shdev_prskubernetes_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_prskubernetes
    ADD CONSTRAINT shdev_prskubernetes_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_prsmisc shdev_prsmisc_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_prsmisc
    ADD CONSTRAINT shdev_prsmisc_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_prsmulticluster shdev_prsmulticluster_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_prsmulticluster
    ADD CONSTRAINT shdev_prsmulticluster_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_prsnetworking shdev_prsnetworking_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_prsnetworking
    ADD CONSTRAINT shdev_prsnetworking_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_prsnode shdev_prsnode_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_prsnode
    ADD CONSTRAINT shdev_prsnode_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_prsproject shdev_prsproject_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_prsproject
    ADD CONSTRAINT shdev_prsproject_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_prsprojectinfra shdev_prsprojectinfra_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_prsprojectinfra
    ADD CONSTRAINT shdev_prsprojectinfra_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_prssigservicecatalog shdev_prssigservicecatalog_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_prssigservicecatalog
    ADD CONSTRAINT shdev_prssigservicecatalog_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_prsstorage shdev_prsstorage_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_prsstorage
    ADD CONSTRAINT shdev_prsstorage_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_prsui shdev_prsui_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_prsui
    ADD CONSTRAINT shdev_prsui_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_pushesall shdev_pushesall_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_pushesall
    ADD CONSTRAINT shdev_pushesall_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_pushesapimachinery shdev_pushesapimachinery_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_pushesapimachinery
    ADD CONSTRAINT shdev_pushesapimachinery_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_pushesapps shdev_pushesapps_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_pushesapps
    ADD CONSTRAINT shdev_pushesapps_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_pushesautoscalingandmonitoring shdev_pushesautoscalingandmonitoring_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_pushesautoscalingandmonitoring
    ADD CONSTRAINT shdev_pushesautoscalingandmonitoring_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_pushesclients shdev_pushesclients_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_pushesclients
    ADD CONSTRAINT shdev_pushesclients_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_pushesclusterlifecycle shdev_pushesclusterlifecycle_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_pushesclusterlifecycle
    ADD CONSTRAINT shdev_pushesclusterlifecycle_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_pushescontrib shdev_pushescontrib_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_pushescontrib
    ADD CONSTRAINT shdev_pushescontrib_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_pushescsi shdev_pushescsi_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_pushescsi
    ADD CONSTRAINT shdev_pushescsi_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_pushesdocs shdev_pushesdocs_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_pushesdocs
    ADD CONSTRAINT shdev_pushesdocs_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_pusheskubernetes shdev_pusheskubernetes_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_pusheskubernetes
    ADD CONSTRAINT shdev_pusheskubernetes_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_pushesmisc shdev_pushesmisc_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_pushesmisc
    ADD CONSTRAINT shdev_pushesmisc_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_pushesmulticluster shdev_pushesmulticluster_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_pushesmulticluster
    ADD CONSTRAINT shdev_pushesmulticluster_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_pushesnetworking shdev_pushesnetworking_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_pushesnetworking
    ADD CONSTRAINT shdev_pushesnetworking_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_pushesnode shdev_pushesnode_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_pushesnode
    ADD CONSTRAINT shdev_pushesnode_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_pushesproject shdev_pushesproject_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_pushesproject
    ADD CONSTRAINT shdev_pushesproject_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_pushesprojectinfra shdev_pushesprojectinfra_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_pushesprojectinfra
    ADD CONSTRAINT shdev_pushesprojectinfra_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_pushessigservicecatalog shdev_pushessigservicecatalog_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_pushessigservicecatalog
    ADD CONSTRAINT shdev_pushessigservicecatalog_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_pushesstorage shdev_pushesstorage_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_pushesstorage
    ADD CONSTRAINT shdev_pushesstorage_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_pushesui shdev_pushesui_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_pushesui
    ADD CONSTRAINT shdev_pushesui_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_review_commentsall shdev_review_commentsall_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_review_commentsall
    ADD CONSTRAINT shdev_review_commentsall_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_review_commentsapimachinery shdev_review_commentsapimachinery_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_review_commentsapimachinery
    ADD CONSTRAINT shdev_review_commentsapimachinery_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_review_commentsapps shdev_review_commentsapps_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_review_commentsapps
    ADD CONSTRAINT shdev_review_commentsapps_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_review_commentsautoscalingandmonitoring shdev_review_commentsautoscalingandmonitoring_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_review_commentsautoscalingandmonitoring
    ADD CONSTRAINT shdev_review_commentsautoscalingandmonitoring_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_review_commentsclients shdev_review_commentsclients_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_review_commentsclients
    ADD CONSTRAINT shdev_review_commentsclients_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_review_commentsclusterlifecycle shdev_review_commentsclusterlifecycle_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_review_commentsclusterlifecycle
    ADD CONSTRAINT shdev_review_commentsclusterlifecycle_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_review_commentscontrib shdev_review_commentscontrib_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_review_commentscontrib
    ADD CONSTRAINT shdev_review_commentscontrib_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_review_commentscsi shdev_review_commentscsi_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_review_commentscsi
    ADD CONSTRAINT shdev_review_commentscsi_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_review_commentsdocs shdev_review_commentsdocs_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_review_commentsdocs
    ADD CONSTRAINT shdev_review_commentsdocs_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_review_commentskubernetes shdev_review_commentskubernetes_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_review_commentskubernetes
    ADD CONSTRAINT shdev_review_commentskubernetes_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_review_commentsmisc shdev_review_commentsmisc_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_review_commentsmisc
    ADD CONSTRAINT shdev_review_commentsmisc_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_review_commentsmulticluster shdev_review_commentsmulticluster_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_review_commentsmulticluster
    ADD CONSTRAINT shdev_review_commentsmulticluster_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_review_commentsnetworking shdev_review_commentsnetworking_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_review_commentsnetworking
    ADD CONSTRAINT shdev_review_commentsnetworking_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_review_commentsnode shdev_review_commentsnode_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_review_commentsnode
    ADD CONSTRAINT shdev_review_commentsnode_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_review_commentsproject shdev_review_commentsproject_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_review_commentsproject
    ADD CONSTRAINT shdev_review_commentsproject_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_review_commentsprojectinfra shdev_review_commentsprojectinfra_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_review_commentsprojectinfra
    ADD CONSTRAINT shdev_review_commentsprojectinfra_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_review_commentssigservicecatalog shdev_review_commentssigservicecatalog_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_review_commentssigservicecatalog
    ADD CONSTRAINT shdev_review_commentssigservicecatalog_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_review_commentsstorage shdev_review_commentsstorage_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_review_commentsstorage
    ADD CONSTRAINT shdev_review_commentsstorage_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_review_commentsui shdev_review_commentsui_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_review_commentsui
    ADD CONSTRAINT shdev_review_commentsui_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_reviewsall shdev_reviewsall_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_reviewsall
    ADD CONSTRAINT shdev_reviewsall_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_reviewsapimachinery shdev_reviewsapimachinery_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_reviewsapimachinery
    ADD CONSTRAINT shdev_reviewsapimachinery_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_reviewsapps shdev_reviewsapps_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_reviewsapps
    ADD CONSTRAINT shdev_reviewsapps_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_reviewsautoscalingandmonitoring shdev_reviewsautoscalingandmonitoring_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_reviewsautoscalingandmonitoring
    ADD CONSTRAINT shdev_reviewsautoscalingandmonitoring_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_reviewsclients shdev_reviewsclients_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_reviewsclients
    ADD CONSTRAINT shdev_reviewsclients_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_reviewsclusterlifecycle shdev_reviewsclusterlifecycle_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_reviewsclusterlifecycle
    ADD CONSTRAINT shdev_reviewsclusterlifecycle_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_reviewscontrib shdev_reviewscontrib_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_reviewscontrib
    ADD CONSTRAINT shdev_reviewscontrib_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_reviewscsi shdev_reviewscsi_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_reviewscsi
    ADD CONSTRAINT shdev_reviewscsi_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_reviewsdocs shdev_reviewsdocs_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_reviewsdocs
    ADD CONSTRAINT shdev_reviewsdocs_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_reviewskubernetes shdev_reviewskubernetes_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_reviewskubernetes
    ADD CONSTRAINT shdev_reviewskubernetes_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_reviewsmisc shdev_reviewsmisc_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_reviewsmisc
    ADD CONSTRAINT shdev_reviewsmisc_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_reviewsmulticluster shdev_reviewsmulticluster_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_reviewsmulticluster
    ADD CONSTRAINT shdev_reviewsmulticluster_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_reviewsnetworking shdev_reviewsnetworking_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_reviewsnetworking
    ADD CONSTRAINT shdev_reviewsnetworking_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_reviewsnode shdev_reviewsnode_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_reviewsnode
    ADD CONSTRAINT shdev_reviewsnode_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_reviewsproject shdev_reviewsproject_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_reviewsproject
    ADD CONSTRAINT shdev_reviewsproject_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_reviewsprojectinfra shdev_reviewsprojectinfra_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_reviewsprojectinfra
    ADD CONSTRAINT shdev_reviewsprojectinfra_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_reviewssigservicecatalog shdev_reviewssigservicecatalog_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_reviewssigservicecatalog
    ADD CONSTRAINT shdev_reviewssigservicecatalog_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_reviewsstorage shdev_reviewsstorage_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_reviewsstorage
    ADD CONSTRAINT shdev_reviewsstorage_pkey PRIMARY KEY ("time", period);


--
-- Name: shdev_reviewsui shdev_reviewsui_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shdev_reviewsui
    ADD CONSTRAINT shdev_reviewsui_pkey PRIMARY KEY ("time", period);


--
-- Name: shpr_wlsigs shpr_wlsigs_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.shpr_wlsigs
    ADD CONSTRAINT shpr_wlsigs_pkey PRIMARY KEY ("time", period);


--
-- Name: siclosed_lsk siclosed_lsk_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.siclosed_lsk
    ADD CONSTRAINT siclosed_lsk_pkey PRIMARY KEY ("time", series, period);


--
-- Name: sissues_age sissues_age_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.sissues_age
    ADD CONSTRAINT sissues_age_pkey PRIMARY KEY ("time", series, period);


--
-- Name: sissues_milestones sissues_milestones_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.sissues_milestones
    ADD CONSTRAINT sissues_milestones_pkey PRIMARY KEY ("time", series, period);


--
-- Name: snew_contributors snew_contributors_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.snew_contributors
    ADD CONSTRAINT snew_contributors_pkey PRIMARY KEY ("time", series, period);


--
-- Name: snew_issues snew_issues_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.snew_issues
    ADD CONSTRAINT snew_issues_pkey PRIMARY KEY ("time", series, period);


--
-- Name: snum_stats snum_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.snum_stats
    ADD CONSTRAINT snum_stats_pkey PRIMARY KEY ("time", series, period);


--
-- Name: spr_apprappr spr_apprappr_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spr_apprappr
    ADD CONSTRAINT spr_apprappr_pkey PRIMARY KEY ("time", period);


--
-- Name: spr_apprwait spr_apprwait_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spr_apprwait
    ADD CONSTRAINT spr_apprwait_pkey PRIMARY KEY ("time", period);


--
-- Name: spr_authall spr_authall_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spr_authall
    ADD CONSTRAINT spr_authall_pkey PRIMARY KEY ("time", period);


--
-- Name: spr_authapimachinery spr_authapimachinery_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spr_authapimachinery
    ADD CONSTRAINT spr_authapimachinery_pkey PRIMARY KEY ("time", period);


--
-- Name: spr_authapps spr_authapps_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spr_authapps
    ADD CONSTRAINT spr_authapps_pkey PRIMARY KEY ("time", period);


--
-- Name: spr_authautoscalingandmonitoring spr_authautoscalingandmonitoring_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spr_authautoscalingandmonitoring
    ADD CONSTRAINT spr_authautoscalingandmonitoring_pkey PRIMARY KEY ("time", period);


--
-- Name: spr_authclients spr_authclients_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spr_authclients
    ADD CONSTRAINT spr_authclients_pkey PRIMARY KEY ("time", period);


--
-- Name: spr_authclusterlifecycle spr_authclusterlifecycle_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spr_authclusterlifecycle
    ADD CONSTRAINT spr_authclusterlifecycle_pkey PRIMARY KEY ("time", period);


--
-- Name: spr_authcontrib spr_authcontrib_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spr_authcontrib
    ADD CONSTRAINT spr_authcontrib_pkey PRIMARY KEY ("time", period);


--
-- Name: spr_authcsi spr_authcsi_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spr_authcsi
    ADD CONSTRAINT spr_authcsi_pkey PRIMARY KEY ("time", period);


--
-- Name: spr_authdocs spr_authdocs_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spr_authdocs
    ADD CONSTRAINT spr_authdocs_pkey PRIMARY KEY ("time", period);


--
-- Name: spr_authkubernetes spr_authkubernetes_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spr_authkubernetes
    ADD CONSTRAINT spr_authkubernetes_pkey PRIMARY KEY ("time", period);


--
-- Name: spr_authmisc spr_authmisc_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spr_authmisc
    ADD CONSTRAINT spr_authmisc_pkey PRIMARY KEY ("time", period);


--
-- Name: spr_authmulticluster spr_authmulticluster_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spr_authmulticluster
    ADD CONSTRAINT spr_authmulticluster_pkey PRIMARY KEY ("time", period);


--
-- Name: spr_authnetworking spr_authnetworking_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spr_authnetworking
    ADD CONSTRAINT spr_authnetworking_pkey PRIMARY KEY ("time", period);


--
-- Name: spr_authnode spr_authnode_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spr_authnode
    ADD CONSTRAINT spr_authnode_pkey PRIMARY KEY ("time", period);


--
-- Name: spr_authproject spr_authproject_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spr_authproject
    ADD CONSTRAINT spr_authproject_pkey PRIMARY KEY ("time", period);


--
-- Name: spr_authprojectinfra spr_authprojectinfra_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spr_authprojectinfra
    ADD CONSTRAINT spr_authprojectinfra_pkey PRIMARY KEY ("time", period);


--
-- Name: spr_authsigservicecatalog spr_authsigservicecatalog_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spr_authsigservicecatalog
    ADD CONSTRAINT spr_authsigservicecatalog_pkey PRIMARY KEY ("time", period);


--
-- Name: spr_authstorage spr_authstorage_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spr_authstorage
    ADD CONSTRAINT spr_authstorage_pkey PRIMARY KEY ("time", period);


--
-- Name: spr_authui spr_authui_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spr_authui
    ADD CONSTRAINT spr_authui_pkey PRIMARY KEY ("time", period);


--
-- Name: spr_comms_med spr_comms_med_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spr_comms_med
    ADD CONSTRAINT spr_comms_med_pkey PRIMARY KEY ("time", period);


--
-- Name: spr_comms_p85 spr_comms_p85_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spr_comms_p85
    ADD CONSTRAINT spr_comms_p85_pkey PRIMARY KEY ("time", period);


--
-- Name: spr_comms_p95 spr_comms_p95_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spr_comms_p95
    ADD CONSTRAINT spr_comms_p95_pkey PRIMARY KEY ("time", period);


--
-- Name: sprblckall sprblckall_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.sprblckall
    ADD CONSTRAINT sprblckall_pkey PRIMARY KEY ("time", period);


--
-- Name: sprblckdo_not_merge sprblckdo_not_merge_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.sprblckdo_not_merge
    ADD CONSTRAINT sprblckdo_not_merge_pkey PRIMARY KEY ("time", period);


--
-- Name: sprblckneeds_ok_to_test sprblckneeds_ok_to_test_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.sprblckneeds_ok_to_test
    ADD CONSTRAINT sprblckneeds_ok_to_test_pkey PRIMARY KEY ("time", period);


--
-- Name: sprblckno_approve sprblckno_approve_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.sprblckno_approve
    ADD CONSTRAINT sprblckno_approve_pkey PRIMARY KEY ("time", period);


--
-- Name: sprblckno_lgtm sprblckno_lgtm_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.sprblckno_lgtm
    ADD CONSTRAINT sprblckno_lgtm_pkey PRIMARY KEY ("time", period);


--
-- Name: sprblckrelease_note_label_needed sprblckrelease_note_label_needed_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.sprblckrelease_note_label_needed
    ADD CONSTRAINT sprblckrelease_note_label_needed_pkey PRIMARY KEY ("time", period);


--
-- Name: sprs_age sprs_age_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.sprs_age
    ADD CONSTRAINT sprs_age_pkey PRIMARY KEY ("time", series, period);


--
-- Name: sprs_labels sprs_labels_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.sprs_labels
    ADD CONSTRAINT sprs_labels_pkey PRIMARY KEY ("time", series, period);


--
-- Name: sprs_milestones sprs_milestones_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.sprs_milestones
    ADD CONSTRAINT sprs_milestones_pkey PRIMARY KEY ("time", series, period);


--
-- Name: spstatall spstatall_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spstatall
    ADD CONSTRAINT spstatall_pkey PRIMARY KEY ("time", period);


--
-- Name: spstatapimachinery spstatapimachinery_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spstatapimachinery
    ADD CONSTRAINT spstatapimachinery_pkey PRIMARY KEY ("time", period);


--
-- Name: spstatapps spstatapps_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spstatapps
    ADD CONSTRAINT spstatapps_pkey PRIMARY KEY ("time", period);


--
-- Name: spstatautoscalingandmonitoring spstatautoscalingandmonitoring_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spstatautoscalingandmonitoring
    ADD CONSTRAINT spstatautoscalingandmonitoring_pkey PRIMARY KEY ("time", period);


--
-- Name: spstatclients spstatclients_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spstatclients
    ADD CONSTRAINT spstatclients_pkey PRIMARY KEY ("time", period);


--
-- Name: spstatclusterlifecycle spstatclusterlifecycle_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spstatclusterlifecycle
    ADD CONSTRAINT spstatclusterlifecycle_pkey PRIMARY KEY ("time", period);


--
-- Name: spstatcontrib spstatcontrib_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spstatcontrib
    ADD CONSTRAINT spstatcontrib_pkey PRIMARY KEY ("time", period);


--
-- Name: spstatcsi spstatcsi_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spstatcsi
    ADD CONSTRAINT spstatcsi_pkey PRIMARY KEY ("time", period);


--
-- Name: spstatdocs spstatdocs_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spstatdocs
    ADD CONSTRAINT spstatdocs_pkey PRIMARY KEY ("time", period);


--
-- Name: spstatkubernetes spstatkubernetes_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spstatkubernetes
    ADD CONSTRAINT spstatkubernetes_pkey PRIMARY KEY ("time", period);


--
-- Name: spstatmisc spstatmisc_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spstatmisc
    ADD CONSTRAINT spstatmisc_pkey PRIMARY KEY ("time", period);


--
-- Name: spstatmulticluster spstatmulticluster_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spstatmulticluster
    ADD CONSTRAINT spstatmulticluster_pkey PRIMARY KEY ("time", period);


--
-- Name: spstatnetworking spstatnetworking_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spstatnetworking
    ADD CONSTRAINT spstatnetworking_pkey PRIMARY KEY ("time", period);


--
-- Name: spstatnode spstatnode_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spstatnode
    ADD CONSTRAINT spstatnode_pkey PRIMARY KEY ("time", period);


--
-- Name: spstatproject spstatproject_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spstatproject
    ADD CONSTRAINT spstatproject_pkey PRIMARY KEY ("time", period);


--
-- Name: spstatprojectinfra spstatprojectinfra_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spstatprojectinfra
    ADD CONSTRAINT spstatprojectinfra_pkey PRIMARY KEY ("time", period);


--
-- Name: spstatsigservicecatalog spstatsigservicecatalog_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spstatsigservicecatalog
    ADD CONSTRAINT spstatsigservicecatalog_pkey PRIMARY KEY ("time", period);


--
-- Name: spstatstorage spstatstorage_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spstatstorage
    ADD CONSTRAINT spstatstorage_pkey PRIMARY KEY ("time", period);


--
-- Name: spstatui spstatui_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.spstatui
    ADD CONSTRAINT spstatui_pkey PRIMARY KEY ("time", period);


--
-- Name: ssig_pr_wlabs ssig_pr_wlabs_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.ssig_pr_wlabs
    ADD CONSTRAINT ssig_pr_wlabs_pkey PRIMARY KEY ("time", period);


--
-- Name: ssig_pr_wliss ssig_pr_wliss_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.ssig_pr_wliss
    ADD CONSTRAINT ssig_pr_wliss_pkey PRIMARY KEY ("time", period);


--
-- Name: ssig_pr_wlrel ssig_pr_wlrel_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.ssig_pr_wlrel
    ADD CONSTRAINT ssig_pr_wlrel_pkey PRIMARY KEY ("time", period);


--
-- Name: ssig_pr_wlrev ssig_pr_wlrev_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.ssig_pr_wlrev
    ADD CONSTRAINT ssig_pr_wlrev_pkey PRIMARY KEY ("time", period);


--
-- Name: ssigm_lsk ssigm_lsk_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.ssigm_lsk
    ADD CONSTRAINT ssigm_lsk_pkey PRIMARY KEY ("time", series, period);


--
-- Name: ssigm_txt ssigm_txt_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.ssigm_txt
    ADD CONSTRAINT ssigm_txt_pkey PRIMARY KEY ("time", period);


--
-- Name: stime_metrics stime_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.stime_metrics
    ADD CONSTRAINT stime_metrics_pkey PRIMARY KEY ("time", series, period);


--
-- Name: suser_reviews suser_reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.suser_reviews
    ADD CONSTRAINT suser_reviews_pkey PRIMARY KEY ("time", series, period);


--
-- Name: swatchers swatchers_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.swatchers
    ADD CONSTRAINT swatchers_pkey PRIMARY KEY ("time", series, period);


--
-- Name: tall_combined_repo_groups tall_combined_repo_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.tall_combined_repo_groups
    ADD CONSTRAINT tall_combined_repo_groups_pkey PRIMARY KEY ("time");


--
-- Name: tall_milestones tall_milestones_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.tall_milestones
    ADD CONSTRAINT tall_milestones_pkey PRIMARY KEY ("time");


--
-- Name: tall_repo_groups tall_repo_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.tall_repo_groups
    ADD CONSTRAINT tall_repo_groups_pkey PRIMARY KEY ("time");


--
-- Name: tall_repo_names tall_repo_names_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.tall_repo_names
    ADD CONSTRAINT tall_repo_names_pkey PRIMARY KEY ("time");


--
-- Name: tbot_commands tbot_commands_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.tbot_commands
    ADD CONSTRAINT tbot_commands_pkey PRIMARY KEY ("time");


--
-- Name: tcompanies tcompanies_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.tcompanies
    ADD CONSTRAINT tcompanies_pkey PRIMARY KEY ("time");


--
-- Name: tpr_labels_tags tpr_labels_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.tpr_labels_tags
    ADD CONSTRAINT tpr_labels_tags_pkey PRIMARY KEY ("time");


--
-- Name: tpriority_labels_with_all tpriority_labels_with_all_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.tpriority_labels_with_all
    ADD CONSTRAINT tpriority_labels_with_all_pkey PRIMARY KEY ("time");


--
-- Name: tquick_ranges tquick_ranges_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.tquick_ranges
    ADD CONSTRAINT tquick_ranges_pkey PRIMARY KEY ("time");


--
-- Name: trepo_groups trepo_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.trepo_groups
    ADD CONSTRAINT trepo_groups_pkey PRIMARY KEY ("time");


--
-- Name: treviewers treviewers_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.treviewers
    ADD CONSTRAINT treviewers_pkey PRIMARY KEY ("time");


--
-- Name: tsig_mentions_labels tsig_mentions_labels_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.tsig_mentions_labels
    ADD CONSTRAINT tsig_mentions_labels_pkey PRIMARY KEY ("time");


--
-- Name: tsig_mentions_labels_with_all tsig_mentions_labels_with_all_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.tsig_mentions_labels_with_all
    ADD CONSTRAINT tsig_mentions_labels_with_all_pkey PRIMARY KEY ("time");


--
-- Name: tsig_mentions_texts tsig_mentions_texts_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.tsig_mentions_texts
    ADD CONSTRAINT tsig_mentions_texts_pkey PRIMARY KEY ("time");


--
-- Name: tsigm_lbl_kinds tsigm_lbl_kinds_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.tsigm_lbl_kinds
    ADD CONSTRAINT tsigm_lbl_kinds_pkey PRIMARY KEY ("time");


--
-- Name: tsigm_lbl_kinds_with_all tsigm_lbl_kinds_with_all_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.tsigm_lbl_kinds_with_all
    ADD CONSTRAINT tsigm_lbl_kinds_with_all_pkey PRIMARY KEY ("time");


--
-- Name: tsize_labels_with_all tsize_labels_with_all_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.tsize_labels_with_all
    ADD CONSTRAINT tsize_labels_with_all_pkey PRIMARY KEY ("time");


--
-- Name: ttop_repo_names ttop_repo_names_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.ttop_repo_names
    ADD CONSTRAINT ttop_repo_names_pkey PRIMARY KEY ("time");


--
-- Name: ttop_repo_names_with_all ttop_repo_names_with_all_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.ttop_repo_names_with_all
    ADD CONSTRAINT ttop_repo_names_with_all_pkey PRIMARY KEY ("time");


--
-- Name: ttop_repos_with_all ttop_repos_with_all_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.ttop_repos_with_all
    ADD CONSTRAINT ttop_repos_with_all_pkey PRIMARY KEY ("time");


--
-- Name: tusers tusers_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY public.tusers
    ADD CONSTRAINT tusers_pkey PRIMARY KEY ("time");


--
-- Name: issue_labels_issue_id; Type: INDEX; Schema: current_state; Owner: devstats_team
--

CREATE INDEX issue_labels_issue_id ON current_state.issue_labels USING btree (issue_id);


--
-- Name: issue_labels_label_parts; Type: INDEX; Schema: current_state; Owner: devstats_team
--

CREATE INDEX issue_labels_label_parts ON current_state.issue_labels USING btree (prefix, label);


--
-- Name: issue_labels_prefix; Type: INDEX; Schema: current_state; Owner: devstats_team
--

CREATE INDEX issue_labels_prefix ON current_state.issue_labels USING btree (prefix);


--
-- Name: issues_id; Type: INDEX; Schema: current_state; Owner: devstats_team
--

CREATE INDEX issues_id ON current_state.issues USING btree (id);


--
-- Name: issues_milestone; Type: INDEX; Schema: current_state; Owner: devstats_team
--

CREATE INDEX issues_milestone ON current_state.issues USING btree (milestone);


--
-- Name: issues_number; Type: INDEX; Schema: current_state; Owner: devstats_team
--

CREATE INDEX issues_number ON current_state.issues USING btree (number);


--
-- Name: milestones_id; Type: INDEX; Schema: current_state; Owner: devstats_team
--

CREATE INDEX milestones_id ON current_state.milestones USING btree (id);


--
-- Name: milestones_name; Type: INDEX; Schema: current_state; Owner: devstats_team
--

CREATE INDEX milestones_name ON current_state.milestones USING btree (milestone);


--
-- Name: actors_affiliations_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX actors_affiliations_actor_id_idx ON public.gha_actors_affiliations USING btree (actor_id);


--
-- Name: actors_affiliations_company_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX actors_affiliations_company_name_idx ON public.gha_actors_affiliations USING btree (company_name);


--
-- Name: actors_affiliations_dt_from_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX actors_affiliations_dt_from_idx ON public.gha_actors_affiliations USING btree (dt_from);


--
-- Name: actors_affiliations_dt_to_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX actors_affiliations_dt_to_idx ON public.gha_actors_affiliations USING btree (dt_to);


--
-- Name: actors_emails_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX actors_emails_actor_id_idx ON public.gha_actors_emails USING btree (actor_id);


--
-- Name: actors_emails_email_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX actors_emails_email_idx ON public.gha_actors_emails USING btree (email);


--
-- Name: actors_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX actors_login_idx ON public.gha_actors USING btree (login);


--
-- Name: actors_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX actors_name_idx ON public.gha_actors USING btree (name);


--
-- Name: assets_content_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_content_type_idx ON public.gha_assets USING btree (content_type);


--
-- Name: assets_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_created_at_idx ON public.gha_assets USING btree (created_at);


--
-- Name: assets_dup_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_dup_actor_id_idx ON public.gha_assets USING btree (dup_actor_id);


--
-- Name: assets_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_dup_actor_login_idx ON public.gha_assets USING btree (dup_actor_login);


--
-- Name: assets_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_dup_created_at_idx ON public.gha_assets USING btree (dup_created_at);


--
-- Name: assets_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_dup_repo_id_idx ON public.gha_assets USING btree (dup_repo_id);


--
-- Name: assets_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_dup_repo_name_idx ON public.gha_assets USING btree (dup_repo_name);


--
-- Name: assets_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_dup_type_idx ON public.gha_assets USING btree (dup_type);


--
-- Name: assets_dup_uploader_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_dup_uploader_login_idx ON public.gha_assets USING btree (dup_uploader_login);


--
-- Name: assets_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_event_id_idx ON public.gha_assets USING btree (event_id);


--
-- Name: assets_state_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_state_idx ON public.gha_assets USING btree (state);


--
-- Name: assets_updated_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_updated_at_idx ON public.gha_assets USING btree (updated_at);


--
-- Name: assets_uploader_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX assets_uploader_id_idx ON public.gha_assets USING btree (uploader_id);


--
-- Name: branches_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX branches_dup_created_at_idx ON public.gha_branches USING btree (dup_created_at);


--
-- Name: branches_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX branches_dup_type_idx ON public.gha_branches USING btree (dup_type);


--
-- Name: branches_dupn_forkee_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX branches_dupn_forkee_name_idx ON public.gha_branches USING btree (dupn_forkee_name);


--
-- Name: branches_dupn_user_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX branches_dupn_user_login_idx ON public.gha_branches USING btree (dupn_user_login);


--
-- Name: branches_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX branches_event_id_idx ON public.gha_branches USING btree (event_id);


--
-- Name: branches_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX branches_repo_id_idx ON public.gha_branches USING btree (repo_id);


--
-- Name: branches_user_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX branches_user_id_idx ON public.gha_branches USING btree (user_id);


--
-- Name: comments_commit_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_commit_id_idx ON public.gha_comments USING btree (commit_id);


--
-- Name: comments_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_created_at_idx ON public.gha_comments USING btree (created_at);


--
-- Name: comments_dup_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_dup_actor_id_idx ON public.gha_comments USING btree (dup_actor_id);


--
-- Name: comments_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_dup_actor_login_idx ON public.gha_comments USING btree (dup_actor_login);


--
-- Name: comments_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_dup_created_at_idx ON public.gha_comments USING btree (dup_created_at);


--
-- Name: comments_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_dup_repo_id_idx ON public.gha_comments USING btree (dup_repo_id);


--
-- Name: comments_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_dup_repo_name_idx ON public.gha_comments USING btree (dup_repo_name);


--
-- Name: comments_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_dup_type_idx ON public.gha_comments USING btree (dup_type);


--
-- Name: comments_dup_user_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_dup_user_login_idx ON public.gha_comments USING btree (dup_user_login);


--
-- Name: comments_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_event_id_idx ON public.gha_comments USING btree (event_id);


--
-- Name: comments_pull_request_review_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_pull_request_review_id_idx ON public.gha_comments USING btree (pull_request_review_id);


--
-- Name: comments_updated_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_updated_at_idx ON public.gha_comments USING btree (updated_at);


--
-- Name: comments_user_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX comments_user_id_idx ON public.gha_comments USING btree (user_id);


--
-- Name: commits_author_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_author_name_idx ON public.gha_commits USING btree (author_name);


--
-- Name: commits_dup_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_dup_actor_id_idx ON public.gha_commits USING btree (dup_actor_id);


--
-- Name: commits_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_dup_actor_login_idx ON public.gha_commits USING btree (dup_actor_login);


--
-- Name: commits_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_dup_created_at_idx ON public.gha_commits USING btree (dup_created_at);


--
-- Name: commits_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_dup_repo_id_idx ON public.gha_commits USING btree (dup_repo_id);


--
-- Name: commits_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_dup_repo_name_idx ON public.gha_commits USING btree (dup_repo_name);


--
-- Name: commits_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_dup_type_idx ON public.gha_commits USING btree (dup_type);


--
-- Name: commits_encrypted_email_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_encrypted_email_idx ON public.gha_commits USING btree (encrypted_email);


--
-- Name: commits_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_event_id_idx ON public.gha_commits USING btree (event_id);


--
-- Name: commits_files_dt_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_files_dt_idx ON public.gha_commits_files USING btree (dt);


--
-- Name: commits_files_path_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_files_path_idx ON public.gha_commits_files USING btree (path);


--
-- Name: commits_files_sha_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_files_sha_idx ON public.gha_commits_files USING btree (sha);


--
-- Name: commits_files_size_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_files_size_idx ON public.gha_commits_files USING btree (size);


--
-- Name: commits_sha_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX commits_sha_idx ON public.gha_commits USING btree (sha);


--
-- Name: computed_dt_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX computed_dt_idx ON public.gha_computed USING btree (dt);


--
-- Name: computed_metric_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX computed_metric_idx ON public.gha_computed USING btree (metric);


--
-- Name: events_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_actor_id_idx ON public.gha_events USING btree (actor_id);


--
-- Name: events_commits_files_dt_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_commits_files_dt_idx ON public.gha_events_commits_files USING btree (dt);


--
-- Name: events_commits_files_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_commits_files_dup_created_at_idx ON public.gha_events_commits_files USING btree (dup_created_at);


--
-- Name: events_commits_files_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_commits_files_dup_repo_id_idx ON public.gha_events_commits_files USING btree (dup_repo_id);


--
-- Name: events_commits_files_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_commits_files_dup_repo_name_idx ON public.gha_events_commits_files USING btree (dup_repo_name);


--
-- Name: events_commits_files_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_commits_files_dup_type_idx ON public.gha_events_commits_files USING btree (dup_type);


--
-- Name: events_commits_files_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_commits_files_event_id_idx ON public.gha_events_commits_files USING btree (event_id);


--
-- Name: events_commits_files_path_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_commits_files_path_idx ON public.gha_events_commits_files USING btree (path);


--
-- Name: events_commits_files_repo_group_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_commits_files_repo_group_idx ON public.gha_events_commits_files USING btree (repo_group);


--
-- Name: events_commits_files_sha_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_commits_files_sha_idx ON public.gha_events_commits_files USING btree (sha);


--
-- Name: events_commits_files_size_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_commits_files_size_idx ON public.gha_events_commits_files USING btree (size);


--
-- Name: events_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_created_at_idx ON public.gha_events USING btree (created_at);


--
-- Name: events_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_dup_actor_login_idx ON public.gha_events USING btree (dup_actor_login);


--
-- Name: events_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_dup_repo_name_idx ON public.gha_events USING btree (dup_repo_name);


--
-- Name: events_forkee_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_forkee_id_idx ON public.gha_events USING btree (forkee_id);


--
-- Name: events_org_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_org_id_idx ON public.gha_events USING btree (org_id);


--
-- Name: events_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_repo_id_idx ON public.gha_events USING btree (repo_id);


--
-- Name: events_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX events_type_idx ON public.gha_events USING btree (type);


--
-- Name: forkees_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_created_at_idx ON public.gha_forkees USING btree (created_at);


--
-- Name: forkees_dup_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_dup_actor_id_idx ON public.gha_forkees USING btree (dup_actor_id);


--
-- Name: forkees_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_dup_actor_login_idx ON public.gha_forkees USING btree (dup_actor_login);


--
-- Name: forkees_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_dup_created_at_idx ON public.gha_forkees USING btree (dup_created_at);


--
-- Name: forkees_dup_owner_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_dup_owner_login_idx ON public.gha_forkees USING btree (dup_owner_login);


--
-- Name: forkees_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_dup_repo_id_idx ON public.gha_forkees USING btree (dup_repo_id);


--
-- Name: forkees_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_dup_repo_name_idx ON public.gha_forkees USING btree (dup_repo_name);


--
-- Name: forkees_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_dup_type_idx ON public.gha_forkees USING btree (dup_type);


--
-- Name: forkees_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_event_id_idx ON public.gha_forkees USING btree (event_id);


--
-- Name: forkees_language_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_language_idx ON public.gha_forkees USING btree (language);


--
-- Name: forkees_organization_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_organization_idx ON public.gha_forkees USING btree (organization);


--
-- Name: forkees_owner_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_owner_id_idx ON public.gha_forkees USING btree (owner_id);


--
-- Name: forkees_updated_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX forkees_updated_at_idx ON public.gha_forkees USING btree (updated_at);


--
-- Name: iall_combined_repo_groupsall_combined_repo_group_name; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iall_combined_repo_groupsall_combined_repo_group_name ON public.tall_combined_repo_groups USING btree (all_combined_repo_group_name);


--
-- Name: iall_combined_repo_groupsall_combined_repo_group_value; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iall_combined_repo_groupsall_combined_repo_group_value ON public.tall_combined_repo_groups USING btree (all_combined_repo_group_value);


--
-- Name: iall_milestonesall_milestones_name; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iall_milestonesall_milestones_name ON public.tall_milestones USING btree (all_milestones_name);


--
-- Name: iall_milestonesall_milestones_value; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iall_milestonesall_milestones_value ON public.tall_milestones USING btree (all_milestones_value);


--
-- Name: iall_repo_groupsall_repo_group_name; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iall_repo_groupsall_repo_group_name ON public.tall_repo_groups USING btree (all_repo_group_name);


--
-- Name: iall_repo_groupsall_repo_group_value; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iall_repo_groupsall_repo_group_value ON public.tall_repo_groups USING btree (all_repo_group_value);


--
-- Name: iall_repo_namesall_repo_names_name; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iall_repo_namesall_repo_names_name ON public.tall_repo_names USING btree (all_repo_names_name);


--
-- Name: iall_repo_namesall_repo_names_value; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iall_repo_namesall_repo_names_value ON public.tall_repo_names USING btree (all_repo_names_value);


--
-- Name: iannotationsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iannotationsp ON public.sannotations USING btree (period);


--
-- Name: iannotationst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iannotationst ON public.sannotations USING btree ("time");


--
-- Name: ibot_commandsbot_command_name; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ibot_commandsbot_command_name ON public.tbot_commands USING btree (bot_command_name);


--
-- Name: ibot_commandsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ibot_commandsp ON public.sbot_commands USING btree (period);


--
-- Name: ibot_commandss; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ibot_commandss ON public.sbot_commands USING btree (series);


--
-- Name: ibot_commandst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ibot_commandst ON public.sbot_commands USING btree ("time");


--
-- Name: icompaniescompanies_name; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX icompaniescompanies_name ON public.tcompanies USING btree (companies_name);


--
-- Name: icompany_activityp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX icompany_activityp ON public.scompany_activity USING btree (period);


--
-- Name: icompany_activitys; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX icompany_activitys ON public.scompany_activity USING btree (series);


--
-- Name: icompany_activityt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX icompany_activityt ON public.scompany_activity USING btree ("time");


--
-- Name: iepisodic_contributorsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iepisodic_contributorsp ON public.sepisodic_contributors USING btree (period);


--
-- Name: iepisodic_contributorss; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iepisodic_contributorss ON public.sepisodic_contributors USING btree (series);


--
-- Name: iepisodic_contributorst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iepisodic_contributorst ON public.sepisodic_contributors USING btree ("time");


--
-- Name: iepisodic_issuesp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iepisodic_issuesp ON public.sepisodic_issues USING btree (period);


--
-- Name: iepisodic_issuess; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iepisodic_issuess ON public.sepisodic_issues USING btree (series);


--
-- Name: iepisodic_issuest; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iepisodic_issuest ON public.sepisodic_issues USING btree ("time");


--
-- Name: ievents_hp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ievents_hp ON public.sevents_h USING btree (period);


--
-- Name: ievents_ht; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ievents_ht ON public.sevents_h USING btree ("time");


--
-- Name: ifirst_non_authorp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ifirst_non_authorp ON public.sfirst_non_author USING btree (period);


--
-- Name: ifirst_non_authors; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ifirst_non_authors ON public.sfirst_non_author USING btree (series);


--
-- Name: ifirst_non_authort; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ifirst_non_authort ON public.sfirst_non_author USING btree ("time");


--
-- Name: igh_stats_rgrpp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX igh_stats_rgrpp ON public.sgh_stats_rgrp USING btree (period);


--
-- Name: igh_stats_rgrps; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX igh_stats_rgrps ON public.sgh_stats_rgrp USING btree (series);


--
-- Name: igh_stats_rgrpt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX igh_stats_rgrpt ON public.sgh_stats_rgrp USING btree ("time");


--
-- Name: igh_stats_rp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX igh_stats_rp ON public.sgh_stats_r USING btree (period);


--
-- Name: igh_stats_rs; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX igh_stats_rs ON public.sgh_stats_r USING btree (series);


--
-- Name: igh_stats_rt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX igh_stats_rt ON public.sgh_stats_r USING btree ("time");


--
-- Name: ihcomcommentersp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomcommentersp ON public.shcomcommenters USING btree (period);


--
-- Name: ihcomcommenterst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomcommenterst ON public.shcomcommenters USING btree ("time");


--
-- Name: ihcomcommentsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomcommentsp ON public.shcomcomments USING btree (period);


--
-- Name: ihcomcommentst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomcommentst ON public.shcomcomments USING btree ("time");


--
-- Name: ihcomcommitcommentersp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomcommitcommentersp ON public.shcomcommitcommenters USING btree (period);


--
-- Name: ihcomcommitcommenterst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomcommitcommenterst ON public.shcomcommitcommenters USING btree ("time");


--
-- Name: ihcomcommitsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomcommitsp ON public.shcomcommits USING btree (period);


--
-- Name: ihcomcommitst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomcommitst ON public.shcomcommits USING btree ("time");


--
-- Name: ihcomcommittersp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomcommittersp ON public.shcomcommitters USING btree (period);


--
-- Name: ihcomcommitterst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomcommitterst ON public.shcomcommitters USING btree ("time");


--
-- Name: ihcomcontributionsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomcontributionsp ON public.shcomcontributions USING btree (period);


--
-- Name: ihcomcontributionst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomcontributionst ON public.shcomcontributions USING btree ("time");


--
-- Name: ihcomcontributorsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomcontributorsp ON public.shcomcontributors USING btree (period);


--
-- Name: ihcomcontributorst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomcontributorst ON public.shcomcontributors USING btree ("time");


--
-- Name: ihcomeventsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomeventsp ON public.shcomevents USING btree (period);


--
-- Name: ihcomeventst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomeventst ON public.shcomevents USING btree ("time");


--
-- Name: ihcomforkersp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomforkersp ON public.shcomforkers USING btree (period);


--
-- Name: ihcomforkerst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomforkerst ON public.shcomforkers USING btree ("time");


--
-- Name: ihcomissuecommentersp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomissuecommentersp ON public.shcomissuecommenters USING btree (period);


--
-- Name: ihcomissuecommenterst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomissuecommenterst ON public.shcomissuecommenters USING btree ("time");


--
-- Name: ihcomissuecreatorsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomissuecreatorsp ON public.shcomissuecreators USING btree (period);


--
-- Name: ihcomissuecreatorst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomissuecreatorst ON public.shcomissuecreators USING btree ("time");


--
-- Name: ihcomissuesp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomissuesp ON public.shcomissues USING btree (period);


--
-- Name: ihcomissuest; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomissuest ON public.shcomissues USING btree ("time");


--
-- Name: ihcomprcreatorsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomprcreatorsp ON public.shcomprcreators USING btree (period);


--
-- Name: ihcomprcreatorst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomprcreatorst ON public.shcomprcreators USING btree ("time");


--
-- Name: ihcomprreviewersp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomprreviewersp ON public.shcomprreviewers USING btree (period);


--
-- Name: ihcomprreviewerst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomprreviewerst ON public.shcomprreviewers USING btree ("time");


--
-- Name: ihcomprsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomprsp ON public.shcomprs USING btree (period);


--
-- Name: ihcomprst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomprst ON public.shcomprs USING btree ("time");


--
-- Name: ihcomrepositoriesp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomrepositoriesp ON public.shcomrepositories USING btree (period);


--
-- Name: ihcomrepositoriest; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomrepositoriest ON public.shcomrepositories USING btree ("time");


--
-- Name: ihcomwatchersp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomwatchersp ON public.shcomwatchers USING btree (period);


--
-- Name: ihcomwatcherst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihcomwatcherst ON public.shcomwatchers USING btree ("time");


--
-- Name: ihdev_active_reposallp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposallp ON public.shdev_active_reposall USING btree (period);


--
-- Name: ihdev_active_reposallt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposallt ON public.shdev_active_reposall USING btree ("time");


--
-- Name: ihdev_active_reposapimachineryp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposapimachineryp ON public.shdev_active_reposapimachinery USING btree (period);


--
-- Name: ihdev_active_reposapimachineryt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposapimachineryt ON public.shdev_active_reposapimachinery USING btree ("time");


--
-- Name: ihdev_active_reposappsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposappsp ON public.shdev_active_reposapps USING btree (period);


--
-- Name: ihdev_active_reposappst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposappst ON public.shdev_active_reposapps USING btree ("time");


--
-- Name: ihdev_active_reposautoscalingandmonitoringp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposautoscalingandmonitoringp ON public.shdev_active_reposautoscalingandmonitoring USING btree (period);


--
-- Name: ihdev_active_reposautoscalingandmonitoringt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposautoscalingandmonitoringt ON public.shdev_active_reposautoscalingandmonitoring USING btree ("time");


--
-- Name: ihdev_active_reposclientsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposclientsp ON public.shdev_active_reposclients USING btree (period);


--
-- Name: ihdev_active_reposclientst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposclientst ON public.shdev_active_reposclients USING btree ("time");


--
-- Name: ihdev_active_reposclusterlifecyclep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposclusterlifecyclep ON public.shdev_active_reposclusterlifecycle USING btree (period);


--
-- Name: ihdev_active_reposclusterlifecyclet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposclusterlifecyclet ON public.shdev_active_reposclusterlifecycle USING btree ("time");


--
-- Name: ihdev_active_reposcsip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposcsip ON public.shdev_active_reposcsi USING btree (period);


--
-- Name: ihdev_active_reposcsit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposcsit ON public.shdev_active_reposcsi USING btree ("time");


--
-- Name: ihdev_active_reposdocsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposdocsp ON public.shdev_active_reposdocs USING btree (period);


--
-- Name: ihdev_active_reposdocst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposdocst ON public.shdev_active_reposdocs USING btree ("time");


--
-- Name: ihdev_active_reposkubernetesp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposkubernetesp ON public.shdev_active_reposkubernetes USING btree (period);


--
-- Name: ihdev_active_reposkubernetest; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposkubernetest ON public.shdev_active_reposkubernetes USING btree ("time");


--
-- Name: ihdev_active_reposmiscp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposmiscp ON public.shdev_active_reposmisc USING btree (period);


--
-- Name: ihdev_active_reposmisct; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposmisct ON public.shdev_active_reposmisc USING btree ("time");


--
-- Name: ihdev_active_reposnetworkingp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposnetworkingp ON public.shdev_active_reposnetworking USING btree (period);


--
-- Name: ihdev_active_reposnetworkingt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposnetworkingt ON public.shdev_active_reposnetworking USING btree ("time");


--
-- Name: ihdev_active_reposnodep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposnodep ON public.shdev_active_reposnode USING btree (period);


--
-- Name: ihdev_active_reposnodet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposnodet ON public.shdev_active_reposnode USING btree ("time");


--
-- Name: ihdev_active_reposprojectinfrap; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposprojectinfrap ON public.shdev_active_reposprojectinfra USING btree (period);


--
-- Name: ihdev_active_reposprojectinfrat; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposprojectinfrat ON public.shdev_active_reposprojectinfra USING btree ("time");


--
-- Name: ihdev_active_reposprojectp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposprojectp ON public.shdev_active_reposproject USING btree (period);


--
-- Name: ihdev_active_reposprojectt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposprojectt ON public.shdev_active_reposproject USING btree ("time");


--
-- Name: ihdev_active_reposstoragep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposstoragep ON public.shdev_active_reposstorage USING btree (period);


--
-- Name: ihdev_active_reposstoraget; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposstoraget ON public.shdev_active_reposstorage USING btree ("time");


--
-- Name: ihdev_active_reposuip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposuip ON public.shdev_active_reposui USING btree (period);


--
-- Name: ihdev_active_reposuit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_active_reposuit ON public.shdev_active_reposui USING btree ("time");


--
-- Name: ihdev_approvesallp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesallp ON public.shdev_approvesall USING btree (period);


--
-- Name: ihdev_approvesallt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesallt ON public.shdev_approvesall USING btree ("time");


--
-- Name: ihdev_approvesapimachineryp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesapimachineryp ON public.shdev_approvesapimachinery USING btree (period);


--
-- Name: ihdev_approvesapimachineryt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesapimachineryt ON public.shdev_approvesapimachinery USING btree ("time");


--
-- Name: ihdev_approvesappsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesappsp ON public.shdev_approvesapps USING btree (period);


--
-- Name: ihdev_approvesappst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesappst ON public.shdev_approvesapps USING btree ("time");


--
-- Name: ihdev_approvesautoscalingandmonitoringp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesautoscalingandmonitoringp ON public.shdev_approvesautoscalingandmonitoring USING btree (period);


--
-- Name: ihdev_approvesautoscalingandmonitoringt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesautoscalingandmonitoringt ON public.shdev_approvesautoscalingandmonitoring USING btree ("time");


--
-- Name: ihdev_approvesclientsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesclientsp ON public.shdev_approvesclients USING btree (period);


--
-- Name: ihdev_approvesclientst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesclientst ON public.shdev_approvesclients USING btree ("time");


--
-- Name: ihdev_approvesclusterlifecyclep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesclusterlifecyclep ON public.shdev_approvesclusterlifecycle USING btree (period);


--
-- Name: ihdev_approvesclusterlifecyclet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesclusterlifecyclet ON public.shdev_approvesclusterlifecycle USING btree ("time");


--
-- Name: ihdev_approvescontribp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvescontribp ON public.shdev_approvescontrib USING btree (period);


--
-- Name: ihdev_approvescontribt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvescontribt ON public.shdev_approvescontrib USING btree ("time");


--
-- Name: ihdev_approvescsip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvescsip ON public.shdev_approvescsi USING btree (period);


--
-- Name: ihdev_approvescsit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvescsit ON public.shdev_approvescsi USING btree ("time");


--
-- Name: ihdev_approvesdocsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesdocsp ON public.shdev_approvesdocs USING btree (period);


--
-- Name: ihdev_approvesdocst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesdocst ON public.shdev_approvesdocs USING btree ("time");


--
-- Name: ihdev_approveskubernetesp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approveskubernetesp ON public.shdev_approveskubernetes USING btree (period);


--
-- Name: ihdev_approveskubernetest; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approveskubernetest ON public.shdev_approveskubernetes USING btree ("time");


--
-- Name: ihdev_approvesmiscp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesmiscp ON public.shdev_approvesmisc USING btree (period);


--
-- Name: ihdev_approvesmisct; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesmisct ON public.shdev_approvesmisc USING btree ("time");


--
-- Name: ihdev_approvesmulticlusterp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesmulticlusterp ON public.shdev_approvesmulticluster USING btree (period);


--
-- Name: ihdev_approvesmulticlustert; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesmulticlustert ON public.shdev_approvesmulticluster USING btree ("time");


--
-- Name: ihdev_approvesnetworkingp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesnetworkingp ON public.shdev_approvesnetworking USING btree (period);


--
-- Name: ihdev_approvesnetworkingt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesnetworkingt ON public.shdev_approvesnetworking USING btree ("time");


--
-- Name: ihdev_approvesnodep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesnodep ON public.shdev_approvesnode USING btree (period);


--
-- Name: ihdev_approvesnodet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesnodet ON public.shdev_approvesnode USING btree ("time");


--
-- Name: ihdev_approvesprojectinfrap; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesprojectinfrap ON public.shdev_approvesprojectinfra USING btree (period);


--
-- Name: ihdev_approvesprojectinfrat; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesprojectinfrat ON public.shdev_approvesprojectinfra USING btree ("time");


--
-- Name: ihdev_approvesprojectp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesprojectp ON public.shdev_approvesproject USING btree (period);


--
-- Name: ihdev_approvesprojectt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesprojectt ON public.shdev_approvesproject USING btree ("time");


--
-- Name: ihdev_approvessigservicecatalogp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvessigservicecatalogp ON public.shdev_approvessigservicecatalog USING btree (period);


--
-- Name: ihdev_approvessigservicecatalogt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvessigservicecatalogt ON public.shdev_approvessigservicecatalog USING btree ("time");


--
-- Name: ihdev_approvesstoragep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesstoragep ON public.shdev_approvesstorage USING btree (period);


--
-- Name: ihdev_approvesstoraget; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesstoraget ON public.shdev_approvesstorage USING btree ("time");


--
-- Name: ihdev_approvesuip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesuip ON public.shdev_approvesui USING btree (period);


--
-- Name: ihdev_approvesuit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_approvesuit ON public.shdev_approvesui USING btree ("time");


--
-- Name: ihdev_commentsallp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsallp ON public.shdev_commentsall USING btree (period);


--
-- Name: ihdev_commentsallt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsallt ON public.shdev_commentsall USING btree ("time");


--
-- Name: ihdev_commentsapimachineryp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsapimachineryp ON public.shdev_commentsapimachinery USING btree (period);


--
-- Name: ihdev_commentsapimachineryt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsapimachineryt ON public.shdev_commentsapimachinery USING btree ("time");


--
-- Name: ihdev_commentsappsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsappsp ON public.shdev_commentsapps USING btree (period);


--
-- Name: ihdev_commentsappst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsappst ON public.shdev_commentsapps USING btree ("time");


--
-- Name: ihdev_commentsautoscalingandmonitoringp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsautoscalingandmonitoringp ON public.shdev_commentsautoscalingandmonitoring USING btree (period);


--
-- Name: ihdev_commentsautoscalingandmonitoringt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsautoscalingandmonitoringt ON public.shdev_commentsautoscalingandmonitoring USING btree ("time");


--
-- Name: ihdev_commentsclientsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsclientsp ON public.shdev_commentsclients USING btree (period);


--
-- Name: ihdev_commentsclientst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsclientst ON public.shdev_commentsclients USING btree ("time");


--
-- Name: ihdev_commentsclusterlifecyclep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsclusterlifecyclep ON public.shdev_commentsclusterlifecycle USING btree (period);


--
-- Name: ihdev_commentsclusterlifecyclet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsclusterlifecyclet ON public.shdev_commentsclusterlifecycle USING btree ("time");


--
-- Name: ihdev_commentscontribp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentscontribp ON public.shdev_commentscontrib USING btree (period);


--
-- Name: ihdev_commentscontribt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentscontribt ON public.shdev_commentscontrib USING btree ("time");


--
-- Name: ihdev_commentscsip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentscsip ON public.shdev_commentscsi USING btree (period);


--
-- Name: ihdev_commentscsit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentscsit ON public.shdev_commentscsi USING btree ("time");


--
-- Name: ihdev_commentsdocsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsdocsp ON public.shdev_commentsdocs USING btree (period);


--
-- Name: ihdev_commentsdocst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsdocst ON public.shdev_commentsdocs USING btree ("time");


--
-- Name: ihdev_commentskubernetesp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentskubernetesp ON public.shdev_commentskubernetes USING btree (period);


--
-- Name: ihdev_commentskubernetest; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentskubernetest ON public.shdev_commentskubernetes USING btree ("time");


--
-- Name: ihdev_commentsmiscp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsmiscp ON public.shdev_commentsmisc USING btree (period);


--
-- Name: ihdev_commentsmisct; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsmisct ON public.shdev_commentsmisc USING btree ("time");


--
-- Name: ihdev_commentsmulticlusterp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsmulticlusterp ON public.shdev_commentsmulticluster USING btree (period);


--
-- Name: ihdev_commentsmulticlustert; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsmulticlustert ON public.shdev_commentsmulticluster USING btree ("time");


--
-- Name: ihdev_commentsnetworkingp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsnetworkingp ON public.shdev_commentsnetworking USING btree (period);


--
-- Name: ihdev_commentsnetworkingt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsnetworkingt ON public.shdev_commentsnetworking USING btree ("time");


--
-- Name: ihdev_commentsnodep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsnodep ON public.shdev_commentsnode USING btree (period);


--
-- Name: ihdev_commentsnodet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsnodet ON public.shdev_commentsnode USING btree ("time");


--
-- Name: ihdev_commentsprojectinfrap; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsprojectinfrap ON public.shdev_commentsprojectinfra USING btree (period);


--
-- Name: ihdev_commentsprojectinfrat; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsprojectinfrat ON public.shdev_commentsprojectinfra USING btree ("time");


--
-- Name: ihdev_commentsprojectp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsprojectp ON public.shdev_commentsproject USING btree (period);


--
-- Name: ihdev_commentsprojectt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsprojectt ON public.shdev_commentsproject USING btree ("time");


--
-- Name: ihdev_commentssigservicecatalogp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentssigservicecatalogp ON public.shdev_commentssigservicecatalog USING btree (period);


--
-- Name: ihdev_commentssigservicecatalogt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentssigservicecatalogt ON public.shdev_commentssigservicecatalog USING btree ("time");


--
-- Name: ihdev_commentsstoragep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsstoragep ON public.shdev_commentsstorage USING btree (period);


--
-- Name: ihdev_commentsstoraget; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsstoraget ON public.shdev_commentsstorage USING btree ("time");


--
-- Name: ihdev_commentsuip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsuip ON public.shdev_commentsui USING btree (period);


--
-- Name: ihdev_commentsuit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commentsuit ON public.shdev_commentsui USING btree ("time");


--
-- Name: ihdev_commit_commentsallp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsallp ON public.shdev_commit_commentsall USING btree (period);


--
-- Name: ihdev_commit_commentsallt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsallt ON public.shdev_commit_commentsall USING btree ("time");


--
-- Name: ihdev_commit_commentsappsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsappsp ON public.shdev_commit_commentsapps USING btree (period);


--
-- Name: ihdev_commit_commentsappst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsappst ON public.shdev_commit_commentsapps USING btree ("time");


--
-- Name: ihdev_commit_commentsautoscalingandmonitoringp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsautoscalingandmonitoringp ON public.shdev_commit_commentsautoscalingandmonitoring USING btree (period);


--
-- Name: ihdev_commit_commentsautoscalingandmonitoringt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsautoscalingandmonitoringt ON public.shdev_commit_commentsautoscalingandmonitoring USING btree ("time");


--
-- Name: ihdev_commit_commentsclientsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsclientsp ON public.shdev_commit_commentsclients USING btree (period);


--
-- Name: ihdev_commit_commentsclientst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsclientst ON public.shdev_commit_commentsclients USING btree ("time");


--
-- Name: ihdev_commit_commentsclusterlifecyclep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsclusterlifecyclep ON public.shdev_commit_commentsclusterlifecycle USING btree (period);


--
-- Name: ihdev_commit_commentsclusterlifecyclet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsclusterlifecyclet ON public.shdev_commit_commentsclusterlifecycle USING btree ("time");


--
-- Name: ihdev_commit_commentscontribp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentscontribp ON public.shdev_commit_commentscontrib USING btree (period);


--
-- Name: ihdev_commit_commentscontribt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentscontribt ON public.shdev_commit_commentscontrib USING btree ("time");


--
-- Name: ihdev_commit_commentscsip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentscsip ON public.shdev_commit_commentscsi USING btree (period);


--
-- Name: ihdev_commit_commentscsit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentscsit ON public.shdev_commit_commentscsi USING btree ("time");


--
-- Name: ihdev_commit_commentsdocsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsdocsp ON public.shdev_commit_commentsdocs USING btree (period);


--
-- Name: ihdev_commit_commentsdocst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsdocst ON public.shdev_commit_commentsdocs USING btree ("time");


--
-- Name: ihdev_commit_commentskubernetesp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentskubernetesp ON public.shdev_commit_commentskubernetes USING btree (period);


--
-- Name: ihdev_commit_commentskubernetest; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentskubernetest ON public.shdev_commit_commentskubernetes USING btree ("time");


--
-- Name: ihdev_commit_commentsmiscp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsmiscp ON public.shdev_commit_commentsmisc USING btree (period);


--
-- Name: ihdev_commit_commentsmisct; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsmisct ON public.shdev_commit_commentsmisc USING btree ("time");


--
-- Name: ihdev_commit_commentsnetworkingp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsnetworkingp ON public.shdev_commit_commentsnetworking USING btree (period);


--
-- Name: ihdev_commit_commentsnetworkingt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsnetworkingt ON public.shdev_commit_commentsnetworking USING btree ("time");


--
-- Name: ihdev_commit_commentsnodep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsnodep ON public.shdev_commit_commentsnode USING btree (period);


--
-- Name: ihdev_commit_commentsnodet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsnodet ON public.shdev_commit_commentsnode USING btree ("time");


--
-- Name: ihdev_commit_commentsprojectinfrap; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsprojectinfrap ON public.shdev_commit_commentsprojectinfra USING btree (period);


--
-- Name: ihdev_commit_commentsprojectinfrat; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsprojectinfrat ON public.shdev_commit_commentsprojectinfra USING btree ("time");


--
-- Name: ihdev_commit_commentsprojectp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsprojectp ON public.shdev_commit_commentsproject USING btree (period);


--
-- Name: ihdev_commit_commentsprojectt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsprojectt ON public.shdev_commit_commentsproject USING btree ("time");


--
-- Name: ihdev_commit_commentssigservicecatalogp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentssigservicecatalogp ON public.shdev_commit_commentssigservicecatalog USING btree (period);


--
-- Name: ihdev_commit_commentssigservicecatalogt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentssigservicecatalogt ON public.shdev_commit_commentssigservicecatalog USING btree ("time");


--
-- Name: ihdev_commit_commentsstoragep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsstoragep ON public.shdev_commit_commentsstorage USING btree (period);


--
-- Name: ihdev_commit_commentsstoraget; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsstoraget ON public.shdev_commit_commentsstorage USING btree ("time");


--
-- Name: ihdev_commit_commentsuip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsuip ON public.shdev_commit_commentsui USING btree (period);


--
-- Name: ihdev_commit_commentsuit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commit_commentsuit ON public.shdev_commit_commentsui USING btree ("time");


--
-- Name: ihdev_commitsallp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsallp ON public.shdev_commitsall USING btree (period);


--
-- Name: ihdev_commitsallt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsallt ON public.shdev_commitsall USING btree ("time");


--
-- Name: ihdev_commitsapimachineryp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsapimachineryp ON public.shdev_commitsapimachinery USING btree (period);


--
-- Name: ihdev_commitsapimachineryt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsapimachineryt ON public.shdev_commitsapimachinery USING btree ("time");


--
-- Name: ihdev_commitsappsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsappsp ON public.shdev_commitsapps USING btree (period);


--
-- Name: ihdev_commitsappst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsappst ON public.shdev_commitsapps USING btree ("time");


--
-- Name: ihdev_commitsautoscalingandmonitoringp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsautoscalingandmonitoringp ON public.shdev_commitsautoscalingandmonitoring USING btree (period);


--
-- Name: ihdev_commitsautoscalingandmonitoringt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsautoscalingandmonitoringt ON public.shdev_commitsautoscalingandmonitoring USING btree ("time");


--
-- Name: ihdev_commitsclientsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsclientsp ON public.shdev_commitsclients USING btree (period);


--
-- Name: ihdev_commitsclientst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsclientst ON public.shdev_commitsclients USING btree ("time");


--
-- Name: ihdev_commitsclusterlifecyclep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsclusterlifecyclep ON public.shdev_commitsclusterlifecycle USING btree (period);


--
-- Name: ihdev_commitsclusterlifecyclet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsclusterlifecyclet ON public.shdev_commitsclusterlifecycle USING btree ("time");


--
-- Name: ihdev_commitscontribp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitscontribp ON public.shdev_commitscontrib USING btree (period);


--
-- Name: ihdev_commitscontribt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitscontribt ON public.shdev_commitscontrib USING btree ("time");


--
-- Name: ihdev_commitscsip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitscsip ON public.shdev_commitscsi USING btree (period);


--
-- Name: ihdev_commitscsit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitscsit ON public.shdev_commitscsi USING btree ("time");


--
-- Name: ihdev_commitsdocsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsdocsp ON public.shdev_commitsdocs USING btree (period);


--
-- Name: ihdev_commitsdocst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsdocst ON public.shdev_commitsdocs USING btree ("time");


--
-- Name: ihdev_commitskubernetesp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitskubernetesp ON public.shdev_commitskubernetes USING btree (period);


--
-- Name: ihdev_commitskubernetest; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitskubernetest ON public.shdev_commitskubernetes USING btree ("time");


--
-- Name: ihdev_commitsmiscp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsmiscp ON public.shdev_commitsmisc USING btree (period);


--
-- Name: ihdev_commitsmisct; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsmisct ON public.shdev_commitsmisc USING btree ("time");


--
-- Name: ihdev_commitsmulticlusterp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsmulticlusterp ON public.shdev_commitsmulticluster USING btree (period);


--
-- Name: ihdev_commitsmulticlustert; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsmulticlustert ON public.shdev_commitsmulticluster USING btree ("time");


--
-- Name: ihdev_commitsnetworkingp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsnetworkingp ON public.shdev_commitsnetworking USING btree (period);


--
-- Name: ihdev_commitsnetworkingt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsnetworkingt ON public.shdev_commitsnetworking USING btree ("time");


--
-- Name: ihdev_commitsnodep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsnodep ON public.shdev_commitsnode USING btree (period);


--
-- Name: ihdev_commitsnodet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsnodet ON public.shdev_commitsnode USING btree ("time");


--
-- Name: ihdev_commitsprojectinfrap; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsprojectinfrap ON public.shdev_commitsprojectinfra USING btree (period);


--
-- Name: ihdev_commitsprojectinfrat; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsprojectinfrat ON public.shdev_commitsprojectinfra USING btree ("time");


--
-- Name: ihdev_commitsprojectp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsprojectp ON public.shdev_commitsproject USING btree (period);


--
-- Name: ihdev_commitsprojectt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsprojectt ON public.shdev_commitsproject USING btree ("time");


--
-- Name: ihdev_commitssigservicecatalogp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitssigservicecatalogp ON public.shdev_commitssigservicecatalog USING btree (period);


--
-- Name: ihdev_commitssigservicecatalogt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitssigservicecatalogt ON public.shdev_commitssigservicecatalog USING btree ("time");


--
-- Name: ihdev_commitsstoragep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsstoragep ON public.shdev_commitsstorage USING btree (period);


--
-- Name: ihdev_commitsstoraget; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsstoraget ON public.shdev_commitsstorage USING btree ("time");


--
-- Name: ihdev_commitsuip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsuip ON public.shdev_commitsui USING btree (period);


--
-- Name: ihdev_commitsuit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_commitsuit ON public.shdev_commitsui USING btree ("time");


--
-- Name: ihdev_contributionsallp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsallp ON public.shdev_contributionsall USING btree (period);


--
-- Name: ihdev_contributionsallt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsallt ON public.shdev_contributionsall USING btree ("time");


--
-- Name: ihdev_contributionsapimachineryp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsapimachineryp ON public.shdev_contributionsapimachinery USING btree (period);


--
-- Name: ihdev_contributionsapimachineryt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsapimachineryt ON public.shdev_contributionsapimachinery USING btree ("time");


--
-- Name: ihdev_contributionsappsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsappsp ON public.shdev_contributionsapps USING btree (period);


--
-- Name: ihdev_contributionsappst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsappst ON public.shdev_contributionsapps USING btree ("time");


--
-- Name: ihdev_contributionsautoscalingandmonitoringp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsautoscalingandmonitoringp ON public.shdev_contributionsautoscalingandmonitoring USING btree (period);


--
-- Name: ihdev_contributionsautoscalingandmonitoringt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsautoscalingandmonitoringt ON public.shdev_contributionsautoscalingandmonitoring USING btree ("time");


--
-- Name: ihdev_contributionsclientsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsclientsp ON public.shdev_contributionsclients USING btree (period);


--
-- Name: ihdev_contributionsclientst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsclientst ON public.shdev_contributionsclients USING btree ("time");


--
-- Name: ihdev_contributionsclusterlifecyclep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsclusterlifecyclep ON public.shdev_contributionsclusterlifecycle USING btree (period);


--
-- Name: ihdev_contributionsclusterlifecyclet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsclusterlifecyclet ON public.shdev_contributionsclusterlifecycle USING btree ("time");


--
-- Name: ihdev_contributionscontribp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionscontribp ON public.shdev_contributionscontrib USING btree (period);


--
-- Name: ihdev_contributionscontribt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionscontribt ON public.shdev_contributionscontrib USING btree ("time");


--
-- Name: ihdev_contributionscsip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionscsip ON public.shdev_contributionscsi USING btree (period);


--
-- Name: ihdev_contributionscsit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionscsit ON public.shdev_contributionscsi USING btree ("time");


--
-- Name: ihdev_contributionsdocsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsdocsp ON public.shdev_contributionsdocs USING btree (period);


--
-- Name: ihdev_contributionsdocst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsdocst ON public.shdev_contributionsdocs USING btree ("time");


--
-- Name: ihdev_contributionskubernetesp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionskubernetesp ON public.shdev_contributionskubernetes USING btree (period);


--
-- Name: ihdev_contributionskubernetest; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionskubernetest ON public.shdev_contributionskubernetes USING btree ("time");


--
-- Name: ihdev_contributionsmiscp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsmiscp ON public.shdev_contributionsmisc USING btree (period);


--
-- Name: ihdev_contributionsmisct; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsmisct ON public.shdev_contributionsmisc USING btree ("time");


--
-- Name: ihdev_contributionsmulticlusterp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsmulticlusterp ON public.shdev_contributionsmulticluster USING btree (period);


--
-- Name: ihdev_contributionsmulticlustert; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsmulticlustert ON public.shdev_contributionsmulticluster USING btree ("time");


--
-- Name: ihdev_contributionsnetworkingp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsnetworkingp ON public.shdev_contributionsnetworking USING btree (period);


--
-- Name: ihdev_contributionsnetworkingt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsnetworkingt ON public.shdev_contributionsnetworking USING btree ("time");


--
-- Name: ihdev_contributionsnodep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsnodep ON public.shdev_contributionsnode USING btree (period);


--
-- Name: ihdev_contributionsnodet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsnodet ON public.shdev_contributionsnode USING btree ("time");


--
-- Name: ihdev_contributionsprojectinfrap; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsprojectinfrap ON public.shdev_contributionsprojectinfra USING btree (period);


--
-- Name: ihdev_contributionsprojectinfrat; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsprojectinfrat ON public.shdev_contributionsprojectinfra USING btree ("time");


--
-- Name: ihdev_contributionsprojectp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsprojectp ON public.shdev_contributionsproject USING btree (period);


--
-- Name: ihdev_contributionsprojectt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsprojectt ON public.shdev_contributionsproject USING btree ("time");


--
-- Name: ihdev_contributionssigservicecatalogp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionssigservicecatalogp ON public.shdev_contributionssigservicecatalog USING btree (period);


--
-- Name: ihdev_contributionssigservicecatalogt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionssigservicecatalogt ON public.shdev_contributionssigservicecatalog USING btree ("time");


--
-- Name: ihdev_contributionsstoragep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsstoragep ON public.shdev_contributionsstorage USING btree (period);


--
-- Name: ihdev_contributionsstoraget; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsstoraget ON public.shdev_contributionsstorage USING btree ("time");


--
-- Name: ihdev_contributionsuip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsuip ON public.shdev_contributionsui USING btree (period);


--
-- Name: ihdev_contributionsuit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_contributionsuit ON public.shdev_contributionsui USING btree ("time");


--
-- Name: ihdev_eventsallp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsallp ON public.shdev_eventsall USING btree (period);


--
-- Name: ihdev_eventsallt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsallt ON public.shdev_eventsall USING btree ("time");


--
-- Name: ihdev_eventsapimachineryp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsapimachineryp ON public.shdev_eventsapimachinery USING btree (period);


--
-- Name: ihdev_eventsapimachineryt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsapimachineryt ON public.shdev_eventsapimachinery USING btree ("time");


--
-- Name: ihdev_eventsappsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsappsp ON public.shdev_eventsapps USING btree (period);


--
-- Name: ihdev_eventsappst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsappst ON public.shdev_eventsapps USING btree ("time");


--
-- Name: ihdev_eventsautoscalingandmonitoringp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsautoscalingandmonitoringp ON public.shdev_eventsautoscalingandmonitoring USING btree (period);


--
-- Name: ihdev_eventsautoscalingandmonitoringt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsautoscalingandmonitoringt ON public.shdev_eventsautoscalingandmonitoring USING btree ("time");


--
-- Name: ihdev_eventsclientsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsclientsp ON public.shdev_eventsclients USING btree (period);


--
-- Name: ihdev_eventsclientst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsclientst ON public.shdev_eventsclients USING btree ("time");


--
-- Name: ihdev_eventsclusterlifecyclep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsclusterlifecyclep ON public.shdev_eventsclusterlifecycle USING btree (period);


--
-- Name: ihdev_eventsclusterlifecyclet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsclusterlifecyclet ON public.shdev_eventsclusterlifecycle USING btree ("time");


--
-- Name: ihdev_eventscontribp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventscontribp ON public.shdev_eventscontrib USING btree (period);


--
-- Name: ihdev_eventscontribt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventscontribt ON public.shdev_eventscontrib USING btree ("time");


--
-- Name: ihdev_eventscsip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventscsip ON public.shdev_eventscsi USING btree (period);


--
-- Name: ihdev_eventscsit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventscsit ON public.shdev_eventscsi USING btree ("time");


--
-- Name: ihdev_eventsdocsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsdocsp ON public.shdev_eventsdocs USING btree (period);


--
-- Name: ihdev_eventsdocst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsdocst ON public.shdev_eventsdocs USING btree ("time");


--
-- Name: ihdev_eventskubernetesp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventskubernetesp ON public.shdev_eventskubernetes USING btree (period);


--
-- Name: ihdev_eventskubernetest; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventskubernetest ON public.shdev_eventskubernetes USING btree ("time");


--
-- Name: ihdev_eventsmiscp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsmiscp ON public.shdev_eventsmisc USING btree (period);


--
-- Name: ihdev_eventsmisct; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsmisct ON public.shdev_eventsmisc USING btree ("time");


--
-- Name: ihdev_eventsmulticlusterp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsmulticlusterp ON public.shdev_eventsmulticluster USING btree (period);


--
-- Name: ihdev_eventsmulticlustert; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsmulticlustert ON public.shdev_eventsmulticluster USING btree ("time");


--
-- Name: ihdev_eventsnetworkingp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsnetworkingp ON public.shdev_eventsnetworking USING btree (period);


--
-- Name: ihdev_eventsnetworkingt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsnetworkingt ON public.shdev_eventsnetworking USING btree ("time");


--
-- Name: ihdev_eventsnodep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsnodep ON public.shdev_eventsnode USING btree (period);


--
-- Name: ihdev_eventsnodet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsnodet ON public.shdev_eventsnode USING btree ("time");


--
-- Name: ihdev_eventsprojectinfrap; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsprojectinfrap ON public.shdev_eventsprojectinfra USING btree (period);


--
-- Name: ihdev_eventsprojectinfrat; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsprojectinfrat ON public.shdev_eventsprojectinfra USING btree ("time");


--
-- Name: ihdev_eventsprojectp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsprojectp ON public.shdev_eventsproject USING btree (period);


--
-- Name: ihdev_eventsprojectt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsprojectt ON public.shdev_eventsproject USING btree ("time");


--
-- Name: ihdev_eventssigservicecatalogp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventssigservicecatalogp ON public.shdev_eventssigservicecatalog USING btree (period);


--
-- Name: ihdev_eventssigservicecatalogt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventssigservicecatalogt ON public.shdev_eventssigservicecatalog USING btree ("time");


--
-- Name: ihdev_eventsstoragep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsstoragep ON public.shdev_eventsstorage USING btree (period);


--
-- Name: ihdev_eventsstoraget; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsstoraget ON public.shdev_eventsstorage USING btree ("time");


--
-- Name: ihdev_eventsuip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsuip ON public.shdev_eventsui USING btree (period);


--
-- Name: ihdev_eventsuit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_eventsuit ON public.shdev_eventsui USING btree ("time");


--
-- Name: ihdev_issue_commentsallp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsallp ON public.shdev_issue_commentsall USING btree (period);


--
-- Name: ihdev_issue_commentsallt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsallt ON public.shdev_issue_commentsall USING btree ("time");


--
-- Name: ihdev_issue_commentsapimachineryp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsapimachineryp ON public.shdev_issue_commentsapimachinery USING btree (period);


--
-- Name: ihdev_issue_commentsapimachineryt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsapimachineryt ON public.shdev_issue_commentsapimachinery USING btree ("time");


--
-- Name: ihdev_issue_commentsappsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsappsp ON public.shdev_issue_commentsapps USING btree (period);


--
-- Name: ihdev_issue_commentsappst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsappst ON public.shdev_issue_commentsapps USING btree ("time");


--
-- Name: ihdev_issue_commentsautoscalingandmonitoringp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsautoscalingandmonitoringp ON public.shdev_issue_commentsautoscalingandmonitoring USING btree (period);


--
-- Name: ihdev_issue_commentsautoscalingandmonitoringt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsautoscalingandmonitoringt ON public.shdev_issue_commentsautoscalingandmonitoring USING btree ("time");


--
-- Name: ihdev_issue_commentsclientsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsclientsp ON public.shdev_issue_commentsclients USING btree (period);


--
-- Name: ihdev_issue_commentsclientst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsclientst ON public.shdev_issue_commentsclients USING btree ("time");


--
-- Name: ihdev_issue_commentsclusterlifecyclep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsclusterlifecyclep ON public.shdev_issue_commentsclusterlifecycle USING btree (period);


--
-- Name: ihdev_issue_commentsclusterlifecyclet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsclusterlifecyclet ON public.shdev_issue_commentsclusterlifecycle USING btree ("time");


--
-- Name: ihdev_issue_commentscontribp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentscontribp ON public.shdev_issue_commentscontrib USING btree (period);


--
-- Name: ihdev_issue_commentscontribt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentscontribt ON public.shdev_issue_commentscontrib USING btree ("time");


--
-- Name: ihdev_issue_commentscsip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentscsip ON public.shdev_issue_commentscsi USING btree (period);


--
-- Name: ihdev_issue_commentscsit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentscsit ON public.shdev_issue_commentscsi USING btree ("time");


--
-- Name: ihdev_issue_commentsdocsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsdocsp ON public.shdev_issue_commentsdocs USING btree (period);


--
-- Name: ihdev_issue_commentsdocst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsdocst ON public.shdev_issue_commentsdocs USING btree ("time");


--
-- Name: ihdev_issue_commentskubernetesp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentskubernetesp ON public.shdev_issue_commentskubernetes USING btree (period);


--
-- Name: ihdev_issue_commentskubernetest; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentskubernetest ON public.shdev_issue_commentskubernetes USING btree ("time");


--
-- Name: ihdev_issue_commentsmiscp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsmiscp ON public.shdev_issue_commentsmisc USING btree (period);


--
-- Name: ihdev_issue_commentsmisct; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsmisct ON public.shdev_issue_commentsmisc USING btree ("time");


--
-- Name: ihdev_issue_commentsmulticlusterp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsmulticlusterp ON public.shdev_issue_commentsmulticluster USING btree (period);


--
-- Name: ihdev_issue_commentsmulticlustert; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsmulticlustert ON public.shdev_issue_commentsmulticluster USING btree ("time");


--
-- Name: ihdev_issue_commentsnetworkingp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsnetworkingp ON public.shdev_issue_commentsnetworking USING btree (period);


--
-- Name: ihdev_issue_commentsnetworkingt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsnetworkingt ON public.shdev_issue_commentsnetworking USING btree ("time");


--
-- Name: ihdev_issue_commentsnodep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsnodep ON public.shdev_issue_commentsnode USING btree (period);


--
-- Name: ihdev_issue_commentsnodet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsnodet ON public.shdev_issue_commentsnode USING btree ("time");


--
-- Name: ihdev_issue_commentsprojectinfrap; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsprojectinfrap ON public.shdev_issue_commentsprojectinfra USING btree (period);


--
-- Name: ihdev_issue_commentsprojectinfrat; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsprojectinfrat ON public.shdev_issue_commentsprojectinfra USING btree ("time");


--
-- Name: ihdev_issue_commentsprojectp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsprojectp ON public.shdev_issue_commentsproject USING btree (period);


--
-- Name: ihdev_issue_commentsprojectt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsprojectt ON public.shdev_issue_commentsproject USING btree ("time");


--
-- Name: ihdev_issue_commentssigservicecatalogp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentssigservicecatalogp ON public.shdev_issue_commentssigservicecatalog USING btree (period);


--
-- Name: ihdev_issue_commentssigservicecatalogt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentssigservicecatalogt ON public.shdev_issue_commentssigservicecatalog USING btree ("time");


--
-- Name: ihdev_issue_commentsstoragep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsstoragep ON public.shdev_issue_commentsstorage USING btree (period);


--
-- Name: ihdev_issue_commentsstoraget; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsstoraget ON public.shdev_issue_commentsstorage USING btree ("time");


--
-- Name: ihdev_issue_commentsuip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsuip ON public.shdev_issue_commentsui USING btree (period);


--
-- Name: ihdev_issue_commentsuit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issue_commentsuit ON public.shdev_issue_commentsui USING btree ("time");


--
-- Name: ihdev_issuesallp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesallp ON public.shdev_issuesall USING btree (period);


--
-- Name: ihdev_issuesallt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesallt ON public.shdev_issuesall USING btree ("time");


--
-- Name: ihdev_issuesapimachineryp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesapimachineryp ON public.shdev_issuesapimachinery USING btree (period);


--
-- Name: ihdev_issuesapimachineryt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesapimachineryt ON public.shdev_issuesapimachinery USING btree ("time");


--
-- Name: ihdev_issuesappsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesappsp ON public.shdev_issuesapps USING btree (period);


--
-- Name: ihdev_issuesappst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesappst ON public.shdev_issuesapps USING btree ("time");


--
-- Name: ihdev_issuesautoscalingandmonitoringp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesautoscalingandmonitoringp ON public.shdev_issuesautoscalingandmonitoring USING btree (period);


--
-- Name: ihdev_issuesautoscalingandmonitoringt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesautoscalingandmonitoringt ON public.shdev_issuesautoscalingandmonitoring USING btree ("time");


--
-- Name: ihdev_issuesclientsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesclientsp ON public.shdev_issuesclients USING btree (period);


--
-- Name: ihdev_issuesclientst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesclientst ON public.shdev_issuesclients USING btree ("time");


--
-- Name: ihdev_issuesclusterlifecyclep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesclusterlifecyclep ON public.shdev_issuesclusterlifecycle USING btree (period);


--
-- Name: ihdev_issuesclusterlifecyclet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesclusterlifecyclet ON public.shdev_issuesclusterlifecycle USING btree ("time");


--
-- Name: ihdev_issuescontribp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuescontribp ON public.shdev_issuescontrib USING btree (period);


--
-- Name: ihdev_issuescontribt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuescontribt ON public.shdev_issuescontrib USING btree ("time");


--
-- Name: ihdev_issuescsip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuescsip ON public.shdev_issuescsi USING btree (period);


--
-- Name: ihdev_issuescsit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuescsit ON public.shdev_issuescsi USING btree ("time");


--
-- Name: ihdev_issuesdocsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesdocsp ON public.shdev_issuesdocs USING btree (period);


--
-- Name: ihdev_issuesdocst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesdocst ON public.shdev_issuesdocs USING btree ("time");


--
-- Name: ihdev_issueskubernetesp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issueskubernetesp ON public.shdev_issueskubernetes USING btree (period);


--
-- Name: ihdev_issueskubernetest; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issueskubernetest ON public.shdev_issueskubernetes USING btree ("time");


--
-- Name: ihdev_issuesmiscp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesmiscp ON public.shdev_issuesmisc USING btree (period);


--
-- Name: ihdev_issuesmisct; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesmisct ON public.shdev_issuesmisc USING btree ("time");


--
-- Name: ihdev_issuesmulticlusterp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesmulticlusterp ON public.shdev_issuesmulticluster USING btree (period);


--
-- Name: ihdev_issuesmulticlustert; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesmulticlustert ON public.shdev_issuesmulticluster USING btree ("time");


--
-- Name: ihdev_issuesnetworkingp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesnetworkingp ON public.shdev_issuesnetworking USING btree (period);


--
-- Name: ihdev_issuesnetworkingt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesnetworkingt ON public.shdev_issuesnetworking USING btree ("time");


--
-- Name: ihdev_issuesnodep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesnodep ON public.shdev_issuesnode USING btree (period);


--
-- Name: ihdev_issuesnodet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesnodet ON public.shdev_issuesnode USING btree ("time");


--
-- Name: ihdev_issuesprojectinfrap; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesprojectinfrap ON public.shdev_issuesprojectinfra USING btree (period);


--
-- Name: ihdev_issuesprojectinfrat; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesprojectinfrat ON public.shdev_issuesprojectinfra USING btree ("time");


--
-- Name: ihdev_issuesprojectp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesprojectp ON public.shdev_issuesproject USING btree (period);


--
-- Name: ihdev_issuesprojectt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesprojectt ON public.shdev_issuesproject USING btree ("time");


--
-- Name: ihdev_issuessigservicecatalogp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuessigservicecatalogp ON public.shdev_issuessigservicecatalog USING btree (period);


--
-- Name: ihdev_issuessigservicecatalogt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuessigservicecatalogt ON public.shdev_issuessigservicecatalog USING btree ("time");


--
-- Name: ihdev_issuesstoragep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesstoragep ON public.shdev_issuesstorage USING btree (period);


--
-- Name: ihdev_issuesstoraget; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesstoraget ON public.shdev_issuesstorage USING btree ("time");


--
-- Name: ihdev_issuesuip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesuip ON public.shdev_issuesui USING btree (period);


--
-- Name: ihdev_issuesuit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_issuesuit ON public.shdev_issuesui USING btree ("time");


--
-- Name: ihdev_prsallp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsallp ON public.shdev_prsall USING btree (period);


--
-- Name: ihdev_prsallt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsallt ON public.shdev_prsall USING btree ("time");


--
-- Name: ihdev_prsapimachineryp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsapimachineryp ON public.shdev_prsapimachinery USING btree (period);


--
-- Name: ihdev_prsapimachineryt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsapimachineryt ON public.shdev_prsapimachinery USING btree ("time");


--
-- Name: ihdev_prsappsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsappsp ON public.shdev_prsapps USING btree (period);


--
-- Name: ihdev_prsappst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsappst ON public.shdev_prsapps USING btree ("time");


--
-- Name: ihdev_prsautoscalingandmonitoringp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsautoscalingandmonitoringp ON public.shdev_prsautoscalingandmonitoring USING btree (period);


--
-- Name: ihdev_prsautoscalingandmonitoringt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsautoscalingandmonitoringt ON public.shdev_prsautoscalingandmonitoring USING btree ("time");


--
-- Name: ihdev_prsclientsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsclientsp ON public.shdev_prsclients USING btree (period);


--
-- Name: ihdev_prsclientst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsclientst ON public.shdev_prsclients USING btree ("time");


--
-- Name: ihdev_prsclusterlifecyclep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsclusterlifecyclep ON public.shdev_prsclusterlifecycle USING btree (period);


--
-- Name: ihdev_prsclusterlifecyclet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsclusterlifecyclet ON public.shdev_prsclusterlifecycle USING btree ("time");


--
-- Name: ihdev_prscontribp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prscontribp ON public.shdev_prscontrib USING btree (period);


--
-- Name: ihdev_prscontribt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prscontribt ON public.shdev_prscontrib USING btree ("time");


--
-- Name: ihdev_prscsip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prscsip ON public.shdev_prscsi USING btree (period);


--
-- Name: ihdev_prscsit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prscsit ON public.shdev_prscsi USING btree ("time");


--
-- Name: ihdev_prsdocsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsdocsp ON public.shdev_prsdocs USING btree (period);


--
-- Name: ihdev_prsdocst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsdocst ON public.shdev_prsdocs USING btree ("time");


--
-- Name: ihdev_prskubernetesp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prskubernetesp ON public.shdev_prskubernetes USING btree (period);


--
-- Name: ihdev_prskubernetest; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prskubernetest ON public.shdev_prskubernetes USING btree ("time");


--
-- Name: ihdev_prsmiscp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsmiscp ON public.shdev_prsmisc USING btree (period);


--
-- Name: ihdev_prsmisct; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsmisct ON public.shdev_prsmisc USING btree ("time");


--
-- Name: ihdev_prsmulticlusterp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsmulticlusterp ON public.shdev_prsmulticluster USING btree (period);


--
-- Name: ihdev_prsmulticlustert; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsmulticlustert ON public.shdev_prsmulticluster USING btree ("time");


--
-- Name: ihdev_prsnetworkingp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsnetworkingp ON public.shdev_prsnetworking USING btree (period);


--
-- Name: ihdev_prsnetworkingt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsnetworkingt ON public.shdev_prsnetworking USING btree ("time");


--
-- Name: ihdev_prsnodep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsnodep ON public.shdev_prsnode USING btree (period);


--
-- Name: ihdev_prsnodet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsnodet ON public.shdev_prsnode USING btree ("time");


--
-- Name: ihdev_prsprojectinfrap; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsprojectinfrap ON public.shdev_prsprojectinfra USING btree (period);


--
-- Name: ihdev_prsprojectinfrat; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsprojectinfrat ON public.shdev_prsprojectinfra USING btree ("time");


--
-- Name: ihdev_prsprojectp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsprojectp ON public.shdev_prsproject USING btree (period);


--
-- Name: ihdev_prsprojectt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsprojectt ON public.shdev_prsproject USING btree ("time");


--
-- Name: ihdev_prssigservicecatalogp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prssigservicecatalogp ON public.shdev_prssigservicecatalog USING btree (period);


--
-- Name: ihdev_prssigservicecatalogt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prssigservicecatalogt ON public.shdev_prssigservicecatalog USING btree ("time");


--
-- Name: ihdev_prsstoragep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsstoragep ON public.shdev_prsstorage USING btree (period);


--
-- Name: ihdev_prsstoraget; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsstoraget ON public.shdev_prsstorage USING btree ("time");


--
-- Name: ihdev_prsuip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsuip ON public.shdev_prsui USING btree (period);


--
-- Name: ihdev_prsuit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_prsuit ON public.shdev_prsui USING btree ("time");


--
-- Name: ihdev_pushesallp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesallp ON public.shdev_pushesall USING btree (period);


--
-- Name: ihdev_pushesallt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesallt ON public.shdev_pushesall USING btree ("time");


--
-- Name: ihdev_pushesapimachineryp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesapimachineryp ON public.shdev_pushesapimachinery USING btree (period);


--
-- Name: ihdev_pushesapimachineryt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesapimachineryt ON public.shdev_pushesapimachinery USING btree ("time");


--
-- Name: ihdev_pushesappsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesappsp ON public.shdev_pushesapps USING btree (period);


--
-- Name: ihdev_pushesappst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesappst ON public.shdev_pushesapps USING btree ("time");


--
-- Name: ihdev_pushesautoscalingandmonitoringp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesautoscalingandmonitoringp ON public.shdev_pushesautoscalingandmonitoring USING btree (period);


--
-- Name: ihdev_pushesautoscalingandmonitoringt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesautoscalingandmonitoringt ON public.shdev_pushesautoscalingandmonitoring USING btree ("time");


--
-- Name: ihdev_pushesclientsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesclientsp ON public.shdev_pushesclients USING btree (period);


--
-- Name: ihdev_pushesclientst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesclientst ON public.shdev_pushesclients USING btree ("time");


--
-- Name: ihdev_pushesclusterlifecyclep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesclusterlifecyclep ON public.shdev_pushesclusterlifecycle USING btree (period);


--
-- Name: ihdev_pushesclusterlifecyclet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesclusterlifecyclet ON public.shdev_pushesclusterlifecycle USING btree ("time");


--
-- Name: ihdev_pushescontribp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushescontribp ON public.shdev_pushescontrib USING btree (period);


--
-- Name: ihdev_pushescontribt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushescontribt ON public.shdev_pushescontrib USING btree ("time");


--
-- Name: ihdev_pushescsip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushescsip ON public.shdev_pushescsi USING btree (period);


--
-- Name: ihdev_pushescsit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushescsit ON public.shdev_pushescsi USING btree ("time");


--
-- Name: ihdev_pushesdocsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesdocsp ON public.shdev_pushesdocs USING btree (period);


--
-- Name: ihdev_pushesdocst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesdocst ON public.shdev_pushesdocs USING btree ("time");


--
-- Name: ihdev_pusheskubernetesp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pusheskubernetesp ON public.shdev_pusheskubernetes USING btree (period);


--
-- Name: ihdev_pusheskubernetest; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pusheskubernetest ON public.shdev_pusheskubernetes USING btree ("time");


--
-- Name: ihdev_pushesmiscp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesmiscp ON public.shdev_pushesmisc USING btree (period);


--
-- Name: ihdev_pushesmisct; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesmisct ON public.shdev_pushesmisc USING btree ("time");


--
-- Name: ihdev_pushesmulticlusterp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesmulticlusterp ON public.shdev_pushesmulticluster USING btree (period);


--
-- Name: ihdev_pushesmulticlustert; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesmulticlustert ON public.shdev_pushesmulticluster USING btree ("time");


--
-- Name: ihdev_pushesnetworkingp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesnetworkingp ON public.shdev_pushesnetworking USING btree (period);


--
-- Name: ihdev_pushesnetworkingt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesnetworkingt ON public.shdev_pushesnetworking USING btree ("time");


--
-- Name: ihdev_pushesnodep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesnodep ON public.shdev_pushesnode USING btree (period);


--
-- Name: ihdev_pushesnodet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesnodet ON public.shdev_pushesnode USING btree ("time");


--
-- Name: ihdev_pushesprojectinfrap; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesprojectinfrap ON public.shdev_pushesprojectinfra USING btree (period);


--
-- Name: ihdev_pushesprojectinfrat; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesprojectinfrat ON public.shdev_pushesprojectinfra USING btree ("time");


--
-- Name: ihdev_pushesprojectp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesprojectp ON public.shdev_pushesproject USING btree (period);


--
-- Name: ihdev_pushesprojectt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesprojectt ON public.shdev_pushesproject USING btree ("time");


--
-- Name: ihdev_pushessigservicecatalogp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushessigservicecatalogp ON public.shdev_pushessigservicecatalog USING btree (period);


--
-- Name: ihdev_pushessigservicecatalogt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushessigservicecatalogt ON public.shdev_pushessigservicecatalog USING btree ("time");


--
-- Name: ihdev_pushesstoragep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesstoragep ON public.shdev_pushesstorage USING btree (period);


--
-- Name: ihdev_pushesstoraget; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesstoraget ON public.shdev_pushesstorage USING btree ("time");


--
-- Name: ihdev_pushesuip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesuip ON public.shdev_pushesui USING btree (period);


--
-- Name: ihdev_pushesuit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_pushesuit ON public.shdev_pushesui USING btree ("time");


--
-- Name: ihdev_review_commentsallp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsallp ON public.shdev_review_commentsall USING btree (period);


--
-- Name: ihdev_review_commentsallt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsallt ON public.shdev_review_commentsall USING btree ("time");


--
-- Name: ihdev_review_commentsapimachineryp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsapimachineryp ON public.shdev_review_commentsapimachinery USING btree (period);


--
-- Name: ihdev_review_commentsapimachineryt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsapimachineryt ON public.shdev_review_commentsapimachinery USING btree ("time");


--
-- Name: ihdev_review_commentsappsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsappsp ON public.shdev_review_commentsapps USING btree (period);


--
-- Name: ihdev_review_commentsappst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsappst ON public.shdev_review_commentsapps USING btree ("time");


--
-- Name: ihdev_review_commentsautoscalingandmonitoringp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsautoscalingandmonitoringp ON public.shdev_review_commentsautoscalingandmonitoring USING btree (period);


--
-- Name: ihdev_review_commentsautoscalingandmonitoringt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsautoscalingandmonitoringt ON public.shdev_review_commentsautoscalingandmonitoring USING btree ("time");


--
-- Name: ihdev_review_commentsclientsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsclientsp ON public.shdev_review_commentsclients USING btree (period);


--
-- Name: ihdev_review_commentsclientst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsclientst ON public.shdev_review_commentsclients USING btree ("time");


--
-- Name: ihdev_review_commentsclusterlifecyclep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsclusterlifecyclep ON public.shdev_review_commentsclusterlifecycle USING btree (period);


--
-- Name: ihdev_review_commentsclusterlifecyclet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsclusterlifecyclet ON public.shdev_review_commentsclusterlifecycle USING btree ("time");


--
-- Name: ihdev_review_commentscontribp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentscontribp ON public.shdev_review_commentscontrib USING btree (period);


--
-- Name: ihdev_review_commentscontribt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentscontribt ON public.shdev_review_commentscontrib USING btree ("time");


--
-- Name: ihdev_review_commentscsip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentscsip ON public.shdev_review_commentscsi USING btree (period);


--
-- Name: ihdev_review_commentscsit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentscsit ON public.shdev_review_commentscsi USING btree ("time");


--
-- Name: ihdev_review_commentsdocsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsdocsp ON public.shdev_review_commentsdocs USING btree (period);


--
-- Name: ihdev_review_commentsdocst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsdocst ON public.shdev_review_commentsdocs USING btree ("time");


--
-- Name: ihdev_review_commentskubernetesp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentskubernetesp ON public.shdev_review_commentskubernetes USING btree (period);


--
-- Name: ihdev_review_commentskubernetest; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentskubernetest ON public.shdev_review_commentskubernetes USING btree ("time");


--
-- Name: ihdev_review_commentsmiscp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsmiscp ON public.shdev_review_commentsmisc USING btree (period);


--
-- Name: ihdev_review_commentsmisct; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsmisct ON public.shdev_review_commentsmisc USING btree ("time");


--
-- Name: ihdev_review_commentsmulticlusterp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsmulticlusterp ON public.shdev_review_commentsmulticluster USING btree (period);


--
-- Name: ihdev_review_commentsmulticlustert; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsmulticlustert ON public.shdev_review_commentsmulticluster USING btree ("time");


--
-- Name: ihdev_review_commentsnetworkingp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsnetworkingp ON public.shdev_review_commentsnetworking USING btree (period);


--
-- Name: ihdev_review_commentsnetworkingt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsnetworkingt ON public.shdev_review_commentsnetworking USING btree ("time");


--
-- Name: ihdev_review_commentsnodep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsnodep ON public.shdev_review_commentsnode USING btree (period);


--
-- Name: ihdev_review_commentsnodet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsnodet ON public.shdev_review_commentsnode USING btree ("time");


--
-- Name: ihdev_review_commentsprojectinfrap; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsprojectinfrap ON public.shdev_review_commentsprojectinfra USING btree (period);


--
-- Name: ihdev_review_commentsprojectinfrat; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsprojectinfrat ON public.shdev_review_commentsprojectinfra USING btree ("time");


--
-- Name: ihdev_review_commentsprojectp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsprojectp ON public.shdev_review_commentsproject USING btree (period);


--
-- Name: ihdev_review_commentsprojectt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsprojectt ON public.shdev_review_commentsproject USING btree ("time");


--
-- Name: ihdev_review_commentssigservicecatalogp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentssigservicecatalogp ON public.shdev_review_commentssigservicecatalog USING btree (period);


--
-- Name: ihdev_review_commentssigservicecatalogt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentssigservicecatalogt ON public.shdev_review_commentssigservicecatalog USING btree ("time");


--
-- Name: ihdev_review_commentsstoragep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsstoragep ON public.shdev_review_commentsstorage USING btree (period);


--
-- Name: ihdev_review_commentsstoraget; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsstoraget ON public.shdev_review_commentsstorage USING btree ("time");


--
-- Name: ihdev_review_commentsuip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsuip ON public.shdev_review_commentsui USING btree (period);


--
-- Name: ihdev_review_commentsuit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_review_commentsuit ON public.shdev_review_commentsui USING btree ("time");


--
-- Name: ihdev_reviewsallp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsallp ON public.shdev_reviewsall USING btree (period);


--
-- Name: ihdev_reviewsallt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsallt ON public.shdev_reviewsall USING btree ("time");


--
-- Name: ihdev_reviewsapimachineryp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsapimachineryp ON public.shdev_reviewsapimachinery USING btree (period);


--
-- Name: ihdev_reviewsapimachineryt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsapimachineryt ON public.shdev_reviewsapimachinery USING btree ("time");


--
-- Name: ihdev_reviewsappsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsappsp ON public.shdev_reviewsapps USING btree (period);


--
-- Name: ihdev_reviewsappst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsappst ON public.shdev_reviewsapps USING btree ("time");


--
-- Name: ihdev_reviewsautoscalingandmonitoringp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsautoscalingandmonitoringp ON public.shdev_reviewsautoscalingandmonitoring USING btree (period);


--
-- Name: ihdev_reviewsautoscalingandmonitoringt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsautoscalingandmonitoringt ON public.shdev_reviewsautoscalingandmonitoring USING btree ("time");


--
-- Name: ihdev_reviewsclientsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsclientsp ON public.shdev_reviewsclients USING btree (period);


--
-- Name: ihdev_reviewsclientst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsclientst ON public.shdev_reviewsclients USING btree ("time");


--
-- Name: ihdev_reviewsclusterlifecyclep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsclusterlifecyclep ON public.shdev_reviewsclusterlifecycle USING btree (period);


--
-- Name: ihdev_reviewsclusterlifecyclet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsclusterlifecyclet ON public.shdev_reviewsclusterlifecycle USING btree ("time");


--
-- Name: ihdev_reviewscontribp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewscontribp ON public.shdev_reviewscontrib USING btree (period);


--
-- Name: ihdev_reviewscontribt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewscontribt ON public.shdev_reviewscontrib USING btree ("time");


--
-- Name: ihdev_reviewscsip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewscsip ON public.shdev_reviewscsi USING btree (period);


--
-- Name: ihdev_reviewscsit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewscsit ON public.shdev_reviewscsi USING btree ("time");


--
-- Name: ihdev_reviewsdocsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsdocsp ON public.shdev_reviewsdocs USING btree (period);


--
-- Name: ihdev_reviewsdocst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsdocst ON public.shdev_reviewsdocs USING btree ("time");


--
-- Name: ihdev_reviewskubernetesp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewskubernetesp ON public.shdev_reviewskubernetes USING btree (period);


--
-- Name: ihdev_reviewskubernetest; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewskubernetest ON public.shdev_reviewskubernetes USING btree ("time");


--
-- Name: ihdev_reviewsmiscp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsmiscp ON public.shdev_reviewsmisc USING btree (period);


--
-- Name: ihdev_reviewsmisct; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsmisct ON public.shdev_reviewsmisc USING btree ("time");


--
-- Name: ihdev_reviewsmulticlusterp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsmulticlusterp ON public.shdev_reviewsmulticluster USING btree (period);


--
-- Name: ihdev_reviewsmulticlustert; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsmulticlustert ON public.shdev_reviewsmulticluster USING btree ("time");


--
-- Name: ihdev_reviewsnetworkingp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsnetworkingp ON public.shdev_reviewsnetworking USING btree (period);


--
-- Name: ihdev_reviewsnetworkingt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsnetworkingt ON public.shdev_reviewsnetworking USING btree ("time");


--
-- Name: ihdev_reviewsnodep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsnodep ON public.shdev_reviewsnode USING btree (period);


--
-- Name: ihdev_reviewsnodet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsnodet ON public.shdev_reviewsnode USING btree ("time");


--
-- Name: ihdev_reviewsprojectinfrap; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsprojectinfrap ON public.shdev_reviewsprojectinfra USING btree (period);


--
-- Name: ihdev_reviewsprojectinfrat; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsprojectinfrat ON public.shdev_reviewsprojectinfra USING btree ("time");


--
-- Name: ihdev_reviewsprojectp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsprojectp ON public.shdev_reviewsproject USING btree (period);


--
-- Name: ihdev_reviewsprojectt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsprojectt ON public.shdev_reviewsproject USING btree ("time");


--
-- Name: ihdev_reviewssigservicecatalogp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewssigservicecatalogp ON public.shdev_reviewssigservicecatalog USING btree (period);


--
-- Name: ihdev_reviewssigservicecatalogt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewssigservicecatalogt ON public.shdev_reviewssigservicecatalog USING btree ("time");


--
-- Name: ihdev_reviewsstoragep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsstoragep ON public.shdev_reviewsstorage USING btree (period);


--
-- Name: ihdev_reviewsstoraget; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsstoraget ON public.shdev_reviewsstorage USING btree ("time");


--
-- Name: ihdev_reviewsuip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsuip ON public.shdev_reviewsui USING btree (period);


--
-- Name: ihdev_reviewsuit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihdev_reviewsuit ON public.shdev_reviewsui USING btree ("time");


--
-- Name: ihpr_wlsigsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihpr_wlsigsp ON public.shpr_wlsigs USING btree (period);


--
-- Name: ihpr_wlsigst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ihpr_wlsigst ON public.shpr_wlsigs USING btree ("time");


--
-- Name: iiclosed_lskp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iiclosed_lskp ON public.siclosed_lsk USING btree (period);


--
-- Name: iiclosed_lsks; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iiclosed_lsks ON public.siclosed_lsk USING btree (series);


--
-- Name: iiclosed_lskt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iiclosed_lskt ON public.siclosed_lsk USING btree ("time");


--
-- Name: iissues_agep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iissues_agep ON public.sissues_age USING btree (period);


--
-- Name: iissues_ages; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iissues_ages ON public.sissues_age USING btree (series);


--
-- Name: iissues_aget; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iissues_aget ON public.sissues_age USING btree ("time");


--
-- Name: iissues_milestonesp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iissues_milestonesp ON public.sissues_milestones USING btree (period);


--
-- Name: iissues_milestoness; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iissues_milestoness ON public.sissues_milestones USING btree (series);


--
-- Name: iissues_milestonest; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iissues_milestonest ON public.sissues_milestones USING btree ("time");


--
-- Name: inew_contributorsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX inew_contributorsp ON public.snew_contributors USING btree (period);


--
-- Name: inew_contributorss; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX inew_contributorss ON public.snew_contributors USING btree (series);


--
-- Name: inew_contributorst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX inew_contributorst ON public.snew_contributors USING btree ("time");


--
-- Name: inew_issuesp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX inew_issuesp ON public.snew_issues USING btree (period);


--
-- Name: inew_issuess; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX inew_issuess ON public.snew_issues USING btree (series);


--
-- Name: inew_issuest; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX inew_issuest ON public.snew_issues USING btree ("time");


--
-- Name: inum_statsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX inum_statsp ON public.snum_stats USING btree (period);


--
-- Name: inum_statss; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX inum_statss ON public.snum_stats USING btree (series);


--
-- Name: inum_statst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX inum_statst ON public.snum_stats USING btree ("time");


--
-- Name: ipr_apprapprp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_apprapprp ON public.spr_apprappr USING btree (period);


--
-- Name: ipr_apprapprt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_apprapprt ON public.spr_apprappr USING btree ("time");


--
-- Name: ipr_apprwaitp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_apprwaitp ON public.spr_apprwait USING btree (period);


--
-- Name: ipr_apprwaitt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_apprwaitt ON public.spr_apprwait USING btree ("time");


--
-- Name: ipr_authallp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authallp ON public.spr_authall USING btree (period);


--
-- Name: ipr_authallt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authallt ON public.spr_authall USING btree ("time");


--
-- Name: ipr_authapimachineryp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authapimachineryp ON public.spr_authapimachinery USING btree (period);


--
-- Name: ipr_authapimachineryt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authapimachineryt ON public.spr_authapimachinery USING btree ("time");


--
-- Name: ipr_authappsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authappsp ON public.spr_authapps USING btree (period);


--
-- Name: ipr_authappst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authappst ON public.spr_authapps USING btree ("time");


--
-- Name: ipr_authautoscalingandmonitoringp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authautoscalingandmonitoringp ON public.spr_authautoscalingandmonitoring USING btree (period);


--
-- Name: ipr_authautoscalingandmonitoringt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authautoscalingandmonitoringt ON public.spr_authautoscalingandmonitoring USING btree ("time");


--
-- Name: ipr_authclientsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authclientsp ON public.spr_authclients USING btree (period);


--
-- Name: ipr_authclientst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authclientst ON public.spr_authclients USING btree ("time");


--
-- Name: ipr_authclusterlifecyclep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authclusterlifecyclep ON public.spr_authclusterlifecycle USING btree (period);


--
-- Name: ipr_authclusterlifecyclet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authclusterlifecyclet ON public.spr_authclusterlifecycle USING btree ("time");


--
-- Name: ipr_authcontribp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authcontribp ON public.spr_authcontrib USING btree (period);


--
-- Name: ipr_authcontribt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authcontribt ON public.spr_authcontrib USING btree ("time");


--
-- Name: ipr_authcsip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authcsip ON public.spr_authcsi USING btree (period);


--
-- Name: ipr_authcsit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authcsit ON public.spr_authcsi USING btree ("time");


--
-- Name: ipr_authdocsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authdocsp ON public.spr_authdocs USING btree (period);


--
-- Name: ipr_authdocst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authdocst ON public.spr_authdocs USING btree ("time");


--
-- Name: ipr_authkubernetesp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authkubernetesp ON public.spr_authkubernetes USING btree (period);


--
-- Name: ipr_authkubernetest; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authkubernetest ON public.spr_authkubernetes USING btree ("time");


--
-- Name: ipr_authmiscp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authmiscp ON public.spr_authmisc USING btree (period);


--
-- Name: ipr_authmisct; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authmisct ON public.spr_authmisc USING btree ("time");


--
-- Name: ipr_authmulticlusterp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authmulticlusterp ON public.spr_authmulticluster USING btree (period);


--
-- Name: ipr_authmulticlustert; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authmulticlustert ON public.spr_authmulticluster USING btree ("time");


--
-- Name: ipr_authnetworkingp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authnetworkingp ON public.spr_authnetworking USING btree (period);


--
-- Name: ipr_authnetworkingt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authnetworkingt ON public.spr_authnetworking USING btree ("time");


--
-- Name: ipr_authnodep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authnodep ON public.spr_authnode USING btree (period);


--
-- Name: ipr_authnodet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authnodet ON public.spr_authnode USING btree ("time");


--
-- Name: ipr_authprojectinfrap; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authprojectinfrap ON public.spr_authprojectinfra USING btree (period);


--
-- Name: ipr_authprojectinfrat; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authprojectinfrat ON public.spr_authprojectinfra USING btree ("time");


--
-- Name: ipr_authprojectp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authprojectp ON public.spr_authproject USING btree (period);


--
-- Name: ipr_authprojectt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authprojectt ON public.spr_authproject USING btree ("time");


--
-- Name: ipr_authsigservicecatalogp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authsigservicecatalogp ON public.spr_authsigservicecatalog USING btree (period);


--
-- Name: ipr_authsigservicecatalogt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authsigservicecatalogt ON public.spr_authsigservicecatalog USING btree ("time");


--
-- Name: ipr_authstoragep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authstoragep ON public.spr_authstorage USING btree (period);


--
-- Name: ipr_authstoraget; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authstoraget ON public.spr_authstorage USING btree ("time");


--
-- Name: ipr_authuip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authuip ON public.spr_authui USING btree (period);


--
-- Name: ipr_authuit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_authuit ON public.spr_authui USING btree ("time");


--
-- Name: ipr_comms_medp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_comms_medp ON public.spr_comms_med USING btree (period);


--
-- Name: ipr_comms_medt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_comms_medt ON public.spr_comms_med USING btree ("time");


--
-- Name: ipr_comms_p85p; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_comms_p85p ON public.spr_comms_p85 USING btree (period);


--
-- Name: ipr_comms_p85t; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_comms_p85t ON public.spr_comms_p85 USING btree ("time");


--
-- Name: ipr_comms_p95p; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_comms_p95p ON public.spr_comms_p95 USING btree (period);


--
-- Name: ipr_comms_p95t; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_comms_p95t ON public.spr_comms_p95 USING btree ("time");


--
-- Name: ipr_labels_tagspr_labels_tags_name; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_labels_tagspr_labels_tags_name ON public.tpr_labels_tags USING btree (pr_labels_tags_name);


--
-- Name: ipr_labels_tagspr_labels_tags_value; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipr_labels_tagspr_labels_tags_value ON public.tpr_labels_tags USING btree (pr_labels_tags_value);


--
-- Name: iprblckallp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iprblckallp ON public.sprblckall USING btree (period);


--
-- Name: iprblckallt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iprblckallt ON public.sprblckall USING btree ("time");


--
-- Name: iprblckdo_not_mergep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iprblckdo_not_mergep ON public.sprblckdo_not_merge USING btree (period);


--
-- Name: iprblckdo_not_merget; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iprblckdo_not_merget ON public.sprblckdo_not_merge USING btree ("time");


--
-- Name: iprblckneeds_ok_to_testp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iprblckneeds_ok_to_testp ON public.sprblckneeds_ok_to_test USING btree (period);


--
-- Name: iprblckneeds_ok_to_testt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iprblckneeds_ok_to_testt ON public.sprblckneeds_ok_to_test USING btree ("time");


--
-- Name: iprblckno_approvep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iprblckno_approvep ON public.sprblckno_approve USING btree (period);


--
-- Name: iprblckno_approvet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iprblckno_approvet ON public.sprblckno_approve USING btree ("time");


--
-- Name: iprblckno_lgtmp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iprblckno_lgtmp ON public.sprblckno_lgtm USING btree (period);


--
-- Name: iprblckno_lgtmt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iprblckno_lgtmt ON public.sprblckno_lgtm USING btree ("time");


--
-- Name: iprblckrelease_note_label_neededp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iprblckrelease_note_label_neededp ON public.sprblckrelease_note_label_needed USING btree (period);


--
-- Name: iprblckrelease_note_label_neededt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iprblckrelease_note_label_neededt ON public.sprblckrelease_note_label_needed USING btree ("time");


--
-- Name: ipriority_labels_with_allpriority_labels_name_with_all; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipriority_labels_with_allpriority_labels_name_with_all ON public.tpriority_labels_with_all USING btree (priority_labels_name_with_all);


--
-- Name: ipriority_labels_with_allpriority_labels_value_with_all; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipriority_labels_with_allpriority_labels_value_with_all ON public.tpriority_labels_with_all USING btree (priority_labels_value_with_all);


--
-- Name: iprs_agep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iprs_agep ON public.sprs_age USING btree (period);


--
-- Name: iprs_ages; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iprs_ages ON public.sprs_age USING btree (series);


--
-- Name: iprs_aget; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iprs_aget ON public.sprs_age USING btree ("time");


--
-- Name: iprs_labelsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iprs_labelsp ON public.sprs_labels USING btree (period);


--
-- Name: iprs_labelss; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iprs_labelss ON public.sprs_labels USING btree (series);


--
-- Name: iprs_labelst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iprs_labelst ON public.sprs_labels USING btree ("time");


--
-- Name: iprs_milestonesp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iprs_milestonesp ON public.sprs_milestones USING btree (period);


--
-- Name: iprs_milestoness; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iprs_milestoness ON public.sprs_milestones USING btree (series);


--
-- Name: iprs_milestonest; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iprs_milestonest ON public.sprs_milestones USING btree ("time");


--
-- Name: ipstatallp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatallp ON public.spstatall USING btree (period);


--
-- Name: ipstatallt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatallt ON public.spstatall USING btree ("time");


--
-- Name: ipstatapimachineryp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatapimachineryp ON public.spstatapimachinery USING btree (period);


--
-- Name: ipstatapimachineryt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatapimachineryt ON public.spstatapimachinery USING btree ("time");


--
-- Name: ipstatappsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatappsp ON public.spstatapps USING btree (period);


--
-- Name: ipstatappst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatappst ON public.spstatapps USING btree ("time");


--
-- Name: ipstatautoscalingandmonitoringp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatautoscalingandmonitoringp ON public.spstatautoscalingandmonitoring USING btree (period);


--
-- Name: ipstatautoscalingandmonitoringt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatautoscalingandmonitoringt ON public.spstatautoscalingandmonitoring USING btree ("time");


--
-- Name: ipstatclientsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatclientsp ON public.spstatclients USING btree (period);


--
-- Name: ipstatclientst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatclientst ON public.spstatclients USING btree ("time");


--
-- Name: ipstatclusterlifecyclep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatclusterlifecyclep ON public.spstatclusterlifecycle USING btree (period);


--
-- Name: ipstatclusterlifecyclet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatclusterlifecyclet ON public.spstatclusterlifecycle USING btree ("time");


--
-- Name: ipstatcontribp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatcontribp ON public.spstatcontrib USING btree (period);


--
-- Name: ipstatcontribt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatcontribt ON public.spstatcontrib USING btree ("time");


--
-- Name: ipstatcsip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatcsip ON public.spstatcsi USING btree (period);


--
-- Name: ipstatcsit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatcsit ON public.spstatcsi USING btree ("time");


--
-- Name: ipstatdocsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatdocsp ON public.spstatdocs USING btree (period);


--
-- Name: ipstatdocst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatdocst ON public.spstatdocs USING btree ("time");


--
-- Name: ipstatkubernetesp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatkubernetesp ON public.spstatkubernetes USING btree (period);


--
-- Name: ipstatkubernetest; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatkubernetest ON public.spstatkubernetes USING btree ("time");


--
-- Name: ipstatmiscp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatmiscp ON public.spstatmisc USING btree (period);


--
-- Name: ipstatmisct; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatmisct ON public.spstatmisc USING btree ("time");


--
-- Name: ipstatmulticlusterp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatmulticlusterp ON public.spstatmulticluster USING btree (period);


--
-- Name: ipstatmulticlustert; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatmulticlustert ON public.spstatmulticluster USING btree ("time");


--
-- Name: ipstatnetworkingp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatnetworkingp ON public.spstatnetworking USING btree (period);


--
-- Name: ipstatnetworkingt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatnetworkingt ON public.spstatnetworking USING btree ("time");


--
-- Name: ipstatnodep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatnodep ON public.spstatnode USING btree (period);


--
-- Name: ipstatnodet; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatnodet ON public.spstatnode USING btree ("time");


--
-- Name: ipstatprojectinfrap; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatprojectinfrap ON public.spstatprojectinfra USING btree (period);


--
-- Name: ipstatprojectinfrat; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatprojectinfrat ON public.spstatprojectinfra USING btree ("time");


--
-- Name: ipstatprojectp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatprojectp ON public.spstatproject USING btree (period);


--
-- Name: ipstatprojectt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatprojectt ON public.spstatproject USING btree ("time");


--
-- Name: ipstatsigservicecatalogp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatsigservicecatalogp ON public.spstatsigservicecatalog USING btree (period);


--
-- Name: ipstatsigservicecatalogt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatsigservicecatalogt ON public.spstatsigservicecatalog USING btree ("time");


--
-- Name: ipstatstoragep; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatstoragep ON public.spstatstorage USING btree (period);


--
-- Name: ipstatstoraget; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatstoraget ON public.spstatstorage USING btree ("time");


--
-- Name: ipstatuip; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatuip ON public.spstatui USING btree (period);


--
-- Name: ipstatuit; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ipstatuit ON public.spstatui USING btree ("time");


--
-- Name: iquick_rangesquick_ranges_data; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iquick_rangesquick_ranges_data ON public.tquick_ranges USING btree (quick_ranges_data);


--
-- Name: iquick_rangesquick_ranges_name; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iquick_rangesquick_ranges_name ON public.tquick_ranges USING btree (quick_ranges_name);


--
-- Name: iquick_rangesquick_ranges_suffix; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iquick_rangesquick_ranges_suffix ON public.tquick_ranges USING btree (quick_ranges_suffix);


--
-- Name: irepo_groupsrepo_group_name; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX irepo_groupsrepo_group_name ON public.trepo_groups USING btree (repo_group_name);


--
-- Name: irepo_groupsrepo_group_value; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX irepo_groupsrepo_group_value ON public.trepo_groups USING btree (repo_group_value);


--
-- Name: ireviewersreviewers_name; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX ireviewersreviewers_name ON public.treviewers USING btree (reviewers_name);


--
-- Name: isig_mentions_labels_with_allsig_mentions_labels_name_with_all; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isig_mentions_labels_with_allsig_mentions_labels_name_with_all ON public.tsig_mentions_labels_with_all USING btree (sig_mentions_labels_name_with_all);


--
-- Name: isig_mentions_labels_with_allsig_mentions_labels_value_with_all; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isig_mentions_labels_with_allsig_mentions_labels_value_with_all ON public.tsig_mentions_labels_with_all USING btree (sig_mentions_labels_value_with_all);


--
-- Name: isig_mentions_labelssig_mentions_labels_name; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isig_mentions_labelssig_mentions_labels_name ON public.tsig_mentions_labels USING btree (sig_mentions_labels_name);


--
-- Name: isig_mentions_labelssig_mentions_labels_value; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isig_mentions_labelssig_mentions_labels_value ON public.tsig_mentions_labels USING btree (sig_mentions_labels_value);


--
-- Name: isig_mentions_textssig_mentions_texts_name; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isig_mentions_textssig_mentions_texts_name ON public.tsig_mentions_texts USING btree (sig_mentions_texts_name);


--
-- Name: isig_mentions_textssig_mentions_texts_value; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isig_mentions_textssig_mentions_texts_value ON public.tsig_mentions_texts USING btree (sig_mentions_texts_value);


--
-- Name: isig_pr_wlabsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isig_pr_wlabsp ON public.ssig_pr_wlabs USING btree (period);


--
-- Name: isig_pr_wlabst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isig_pr_wlabst ON public.ssig_pr_wlabs USING btree ("time");


--
-- Name: isig_pr_wlissp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isig_pr_wlissp ON public.ssig_pr_wliss USING btree (period);


--
-- Name: isig_pr_wlisst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isig_pr_wlisst ON public.ssig_pr_wliss USING btree ("time");


--
-- Name: isig_pr_wlrelp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isig_pr_wlrelp ON public.ssig_pr_wlrel USING btree (period);


--
-- Name: isig_pr_wlrelt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isig_pr_wlrelt ON public.ssig_pr_wlrel USING btree ("time");


--
-- Name: isig_pr_wlrevp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isig_pr_wlrevp ON public.ssig_pr_wlrev USING btree (period);


--
-- Name: isig_pr_wlrevt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isig_pr_wlrevt ON public.ssig_pr_wlrev USING btree ("time");


--
-- Name: isigm_lbl_kinds_with_allsigm_lbl_kind_name_with_all; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isigm_lbl_kinds_with_allsigm_lbl_kind_name_with_all ON public.tsigm_lbl_kinds_with_all USING btree (sigm_lbl_kind_name_with_all);


--
-- Name: isigm_lbl_kinds_with_allsigm_lbl_kind_value_with_all; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isigm_lbl_kinds_with_allsigm_lbl_kind_value_with_all ON public.tsigm_lbl_kinds_with_all USING btree (sigm_lbl_kind_value_with_all);


--
-- Name: isigm_lbl_kindssigm_lbl_kind_name; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isigm_lbl_kindssigm_lbl_kind_name ON public.tsigm_lbl_kinds USING btree (sigm_lbl_kind_name);


--
-- Name: isigm_lbl_kindssigm_lbl_kind_value; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isigm_lbl_kindssigm_lbl_kind_value ON public.tsigm_lbl_kinds USING btree (sigm_lbl_kind_value);


--
-- Name: isigm_lskp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isigm_lskp ON public.ssigm_lsk USING btree (period);


--
-- Name: isigm_lsks; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isigm_lsks ON public.ssigm_lsk USING btree (series);


--
-- Name: isigm_lskt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isigm_lskt ON public.ssigm_lsk USING btree ("time");


--
-- Name: isigm_txtp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isigm_txtp ON public.ssigm_txt USING btree (period);


--
-- Name: isigm_txtt; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isigm_txtt ON public.ssigm_txt USING btree ("time");


--
-- Name: isize_labels_with_allsize_labels_name_with_all; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isize_labels_with_allsize_labels_name_with_all ON public.tsize_labels_with_all USING btree (size_labels_name_with_all);


--
-- Name: isize_labels_with_allsize_labels_value_with_all; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX isize_labels_with_allsize_labels_value_with_all ON public.tsize_labels_with_all USING btree (size_labels_value_with_all);


--
-- Name: issues_assignee_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_assignee_id_idx ON public.gha_issues USING btree (assignee_id);


--
-- Name: issues_closed_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_closed_at_idx ON public.gha_issues USING btree (closed_at);


--
-- Name: issues_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_created_at_idx ON public.gha_issues USING btree (created_at);


--
-- Name: issues_dup_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_dup_actor_id_idx ON public.gha_issues USING btree (dup_actor_id);


--
-- Name: issues_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_dup_actor_login_idx ON public.gha_issues USING btree (dup_actor_login);


--
-- Name: issues_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_dup_created_at_idx ON public.gha_issues USING btree (dup_created_at);


--
-- Name: issues_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_dup_repo_id_idx ON public.gha_issues USING btree (dup_repo_id);


--
-- Name: issues_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_dup_repo_name_idx ON public.gha_issues USING btree (dup_repo_name);


--
-- Name: issues_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_dup_type_idx ON public.gha_issues USING btree (dup_type);


--
-- Name: issues_dup_user_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_dup_user_login_idx ON public.gha_issues USING btree (dup_user_login);


--
-- Name: issues_dupn_assignee_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_dupn_assignee_login_idx ON public.gha_issues USING btree (dupn_assignee_login);


--
-- Name: issues_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_event_id_idx ON public.gha_issues USING btree (event_id);


--
-- Name: issues_events_labels_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_events_labels_actor_id_idx ON public.gha_issues_events_labels USING btree (actor_id);


--
-- Name: issues_events_labels_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_events_labels_actor_login_idx ON public.gha_issues_events_labels USING btree (actor_login);


--
-- Name: issues_events_labels_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_events_labels_created_at_idx ON public.gha_issues_events_labels USING btree (created_at);


--
-- Name: issues_events_labels_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_events_labels_event_id_idx ON public.gha_issues_events_labels USING btree (event_id);


--
-- Name: issues_events_labels_issue_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_events_labels_issue_id_idx ON public.gha_issues_events_labels USING btree (issue_id);


--
-- Name: issues_events_labels_issue_number_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_events_labels_issue_number_idx ON public.gha_issues_events_labels USING btree (issue_number);


--
-- Name: issues_events_labels_label_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_events_labels_label_id_idx ON public.gha_issues_events_labels USING btree (label_id);


--
-- Name: issues_events_labels_label_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_events_labels_label_name_idx ON public.gha_issues_events_labels USING btree (label_name);


--
-- Name: issues_events_labels_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_events_labels_repo_id_idx ON public.gha_issues_events_labels USING btree (repo_id);


--
-- Name: issues_events_labels_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_events_labels_repo_name_idx ON public.gha_issues_events_labels USING btree (repo_name);


--
-- Name: issues_events_labels_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_events_labels_type_idx ON public.gha_issues_events_labels USING btree (type);


--
-- Name: issues_is_pull_request_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_is_pull_request_idx ON public.gha_issues USING btree (is_pull_request);


--
-- Name: issues_labels_dup_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_labels_dup_actor_id_idx ON public.gha_issues_labels USING btree (dup_actor_id);


--
-- Name: issues_labels_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_labels_dup_actor_login_idx ON public.gha_issues_labels USING btree (dup_actor_login);


--
-- Name: issues_labels_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_labels_dup_created_at_idx ON public.gha_issues_labels USING btree (dup_created_at);


--
-- Name: issues_labels_dup_issue_number_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_labels_dup_issue_number_idx ON public.gha_issues_labels USING btree (dup_issue_number);


--
-- Name: issues_labels_dup_label_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_labels_dup_label_name_idx ON public.gha_issues_labels USING btree (dup_label_name);


--
-- Name: issues_labels_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_labels_dup_repo_id_idx ON public.gha_issues_labels USING btree (dup_repo_id);


--
-- Name: issues_labels_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_labels_dup_repo_name_idx ON public.gha_issues_labels USING btree (dup_repo_name);


--
-- Name: issues_labels_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_labels_dup_type_idx ON public.gha_issues_labels USING btree (dup_type);


--
-- Name: issues_milestone_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_milestone_id_idx ON public.gha_issues USING btree (milestone_id);


--
-- Name: issues_pull_requests_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_pull_requests_created_at_idx ON public.gha_issues_pull_requests USING btree (created_at);


--
-- Name: issues_pull_requests_issue_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_pull_requests_issue_id_idx ON public.gha_issues_pull_requests USING btree (issue_id);


--
-- Name: issues_pull_requests_number_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_pull_requests_number_idx ON public.gha_issues_pull_requests USING btree (number);


--
-- Name: issues_pull_requests_pull_request_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_pull_requests_pull_request_id_idx ON public.gha_issues_pull_requests USING btree (pull_request_id);


--
-- Name: issues_pull_requests_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_pull_requests_repo_id_idx ON public.gha_issues_pull_requests USING btree (repo_id);


--
-- Name: issues_pull_requests_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_pull_requests_repo_name_idx ON public.gha_issues_pull_requests USING btree (repo_name);


--
-- Name: issues_state_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_state_idx ON public.gha_issues USING btree (state);


--
-- Name: issues_updated_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_updated_at_idx ON public.gha_issues USING btree (updated_at);


--
-- Name: issues_user_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX issues_user_id_idx ON public.gha_issues USING btree (user_id);


--
-- Name: itime_metricsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX itime_metricsp ON public.stime_metrics USING btree (period);


--
-- Name: itime_metricss; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX itime_metricss ON public.stime_metrics USING btree (series);


--
-- Name: itime_metricst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX itime_metricst ON public.stime_metrics USING btree ("time");


--
-- Name: itop_repo_names_with_alltop_repo_names_name_with_all; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX itop_repo_names_with_alltop_repo_names_name_with_all ON public.ttop_repo_names_with_all USING btree (top_repo_names_name_with_all);


--
-- Name: itop_repo_names_with_alltop_repo_names_value_with_all; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX itop_repo_names_with_alltop_repo_names_value_with_all ON public.ttop_repo_names_with_all USING btree (top_repo_names_value_with_all);


--
-- Name: itop_repo_namestop_repo_names_name; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX itop_repo_namestop_repo_names_name ON public.ttop_repo_names USING btree (top_repo_names_name);


--
-- Name: itop_repo_namestop_repo_names_value; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX itop_repo_namestop_repo_names_value ON public.ttop_repo_names USING btree (top_repo_names_value);


--
-- Name: itop_repos_with_alltop_repos_name_with_all; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX itop_repos_with_alltop_repos_name_with_all ON public.ttop_repos_with_all USING btree (top_repos_name_with_all);


--
-- Name: itop_repos_with_alltop_repos_value_with_all; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX itop_repos_with_alltop_repos_value_with_all ON public.ttop_repos_with_all USING btree (top_repos_value_with_all);


--
-- Name: iuser_reviewsp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iuser_reviewsp ON public.suser_reviews USING btree (period);


--
-- Name: iuser_reviewss; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iuser_reviewss ON public.suser_reviews USING btree (series);


--
-- Name: iuser_reviewst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iuser_reviewst ON public.suser_reviews USING btree ("time");


--
-- Name: iusersusers_name; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iusersusers_name ON public.tusers USING btree (users_name);


--
-- Name: iwatchersp; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iwatchersp ON public.swatchers USING btree (period);


--
-- Name: iwatcherss; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iwatcherss ON public.swatchers USING btree (series);


--
-- Name: iwatcherst; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX iwatcherst ON public.swatchers USING btree ("time");


--
-- Name: labels_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX labels_name_idx ON public.gha_labels USING btree (name);


--
-- Name: logs_dt_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX logs_dt_idx ON public.gha_logs USING btree (dt);


--
-- Name: logs_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX logs_id_idx ON public.gha_logs USING btree (id);


--
-- Name: logs_prog_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX logs_prog_idx ON public.gha_logs USING btree (prog);


--
-- Name: logs_proj_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX logs_proj_idx ON public.gha_logs USING btree (proj);


--
-- Name: logs_run_dt_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX logs_run_dt_idx ON public.gha_logs USING btree (run_dt);


--
-- Name: milestones_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_created_at_idx ON public.gha_milestones USING btree (created_at);


--
-- Name: milestones_creator_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_creator_id_idx ON public.gha_milestones USING btree (creator_id);


--
-- Name: milestones_dup_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_dup_actor_id_idx ON public.gha_milestones USING btree (dup_actor_id);


--
-- Name: milestones_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_dup_actor_login_idx ON public.gha_milestones USING btree (dup_actor_login);


--
-- Name: milestones_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_dup_created_at_idx ON public.gha_milestones USING btree (dup_created_at);


--
-- Name: milestones_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_dup_repo_id_idx ON public.gha_milestones USING btree (dup_repo_id);


--
-- Name: milestones_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_dup_repo_name_idx ON public.gha_milestones USING btree (dup_repo_name);


--
-- Name: milestones_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_dup_type_idx ON public.gha_milestones USING btree (dup_type);


--
-- Name: milestones_dupn_creator_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_dupn_creator_login_idx ON public.gha_milestones USING btree (dupn_creator_login);


--
-- Name: milestones_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_event_id_idx ON public.gha_milestones USING btree (event_id);


--
-- Name: milestones_state_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_state_idx ON public.gha_milestones USING btree (state);


--
-- Name: milestones_updated_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX milestones_updated_at_idx ON public.gha_milestones USING btree (updated_at);


--
-- Name: orgs_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX orgs_login_idx ON public.gha_orgs USING btree (login);


--
-- Name: pages_action_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pages_action_idx ON public.gha_pages USING btree (action);


--
-- Name: pages_dup_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pages_dup_actor_id_idx ON public.gha_pages USING btree (dup_actor_id);


--
-- Name: pages_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pages_dup_actor_login_idx ON public.gha_pages USING btree (dup_actor_login);


--
-- Name: pages_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pages_dup_created_at_idx ON public.gha_pages USING btree (dup_created_at);


--
-- Name: pages_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pages_dup_repo_id_idx ON public.gha_pages USING btree (dup_repo_id);


--
-- Name: pages_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pages_dup_repo_name_idx ON public.gha_pages USING btree (dup_repo_name);


--
-- Name: pages_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pages_dup_type_idx ON public.gha_pages USING btree (dup_type);


--
-- Name: pages_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pages_event_id_idx ON public.gha_pages USING btree (event_id);


--
-- Name: parsed_dt_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX parsed_dt_idx ON public.gha_parsed USING btree (dt);


--
-- Name: payloads_action_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_action_idx ON public.gha_payloads USING btree (action);


--
-- Name: payloads_comment_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_comment_id_idx ON public.gha_payloads USING btree (comment_id);


--
-- Name: payloads_commit_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_commit_idx ON public.gha_payloads USING btree (commit);


--
-- Name: payloads_dup_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_dup_actor_id_idx ON public.gha_payloads USING btree (dup_actor_id);


--
-- Name: payloads_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_dup_actor_login_idx ON public.gha_payloads USING btree (dup_actor_login);


--
-- Name: payloads_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_dup_created_at_idx ON public.gha_payloads USING btree (dup_created_at);


--
-- Name: payloads_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_dup_repo_id_idx ON public.gha_payloads USING btree (dup_repo_id);


--
-- Name: payloads_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_dup_repo_name_idx ON public.gha_payloads USING btree (dup_repo_name);


--
-- Name: payloads_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_dup_type_idx ON public.gha_payloads USING btree (dup_type);


--
-- Name: payloads_forkee_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_forkee_id_idx ON public.gha_payloads USING btree (forkee_id);


--
-- Name: payloads_head_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_head_idx ON public.gha_payloads USING btree (head);


--
-- Name: payloads_issue_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_issue_id_idx ON public.gha_payloads USING btree (issue_id);


--
-- Name: payloads_member_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_member_id_idx ON public.gha_payloads USING btree (member_id);


--
-- Name: payloads_pull_request_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_pull_request_id_idx ON public.gha_payloads USING btree (issue_id);


--
-- Name: payloads_ref_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_ref_type_idx ON public.gha_payloads USING btree (ref_type);


--
-- Name: payloads_release_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX payloads_release_id_idx ON public.gha_payloads USING btree (release_id);


--
-- Name: pull_requests_assignee_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_assignee_id_idx ON public.gha_pull_requests USING btree (assignee_id);


--
-- Name: pull_requests_base_sha_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_base_sha_idx ON public.gha_pull_requests USING btree (base_sha);


--
-- Name: pull_requests_closed_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_closed_at_idx ON public.gha_pull_requests USING btree (closed_at);


--
-- Name: pull_requests_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_created_at_idx ON public.gha_pull_requests USING btree (created_at);


--
-- Name: pull_requests_dup_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_dup_actor_id_idx ON public.gha_pull_requests USING btree (dup_actor_id);


--
-- Name: pull_requests_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_dup_actor_login_idx ON public.gha_pull_requests USING btree (dup_actor_login);


--
-- Name: pull_requests_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_dup_created_at_idx ON public.gha_pull_requests USING btree (dup_created_at);


--
-- Name: pull_requests_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_dup_repo_id_idx ON public.gha_pull_requests USING btree (dup_repo_id);


--
-- Name: pull_requests_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_dup_repo_name_idx ON public.gha_pull_requests USING btree (dup_repo_name);


--
-- Name: pull_requests_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_dup_type_idx ON public.gha_pull_requests USING btree (dup_type);


--
-- Name: pull_requests_dup_user_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_dup_user_login_idx ON public.gha_pull_requests USING btree (dup_user_login);


--
-- Name: pull_requests_dupn_assignee_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_dupn_assignee_login_idx ON public.gha_pull_requests USING btree (dupn_assignee_login);


--
-- Name: pull_requests_dupn_merged_by_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_dupn_merged_by_login_idx ON public.gha_pull_requests USING btree (dupn_merged_by_login);


--
-- Name: pull_requests_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_event_id_idx ON public.gha_pull_requests USING btree (event_id);


--
-- Name: pull_requests_head_sha_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_head_sha_idx ON public.gha_pull_requests USING btree (head_sha);


--
-- Name: pull_requests_merged_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_merged_at_idx ON public.gha_pull_requests USING btree (merged_at);


--
-- Name: pull_requests_merged_by_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_merged_by_id_idx ON public.gha_pull_requests USING btree (merged_by_id);


--
-- Name: pull_requests_milestone_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_milestone_id_idx ON public.gha_pull_requests USING btree (milestone_id);


--
-- Name: pull_requests_state_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_state_idx ON public.gha_pull_requests USING btree (state);


--
-- Name: pull_requests_updated_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_updated_at_idx ON public.gha_pull_requests USING btree (updated_at);


--
-- Name: pull_requests_user_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX pull_requests_user_id_idx ON public.gha_pull_requests USING btree (user_id);


--
-- Name: releases_author_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX releases_author_id_idx ON public.gha_releases USING btree (author_id);


--
-- Name: releases_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX releases_created_at_idx ON public.gha_releases USING btree (created_at);


--
-- Name: releases_dup_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX releases_dup_actor_id_idx ON public.gha_releases USING btree (dup_actor_id);


--
-- Name: releases_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX releases_dup_actor_login_idx ON public.gha_releases USING btree (dup_actor_login);


--
-- Name: releases_dup_author_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX releases_dup_author_login_idx ON public.gha_releases USING btree (dup_author_login);


--
-- Name: releases_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX releases_dup_created_at_idx ON public.gha_releases USING btree (dup_created_at);


--
-- Name: releases_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX releases_dup_repo_id_idx ON public.gha_releases USING btree (dup_repo_id);


--
-- Name: releases_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX releases_dup_repo_name_idx ON public.gha_releases USING btree (dup_repo_name);


--
-- Name: releases_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX releases_dup_type_idx ON public.gha_releases USING btree (dup_type);


--
-- Name: releases_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX releases_event_id_idx ON public.gha_releases USING btree (event_id);


--
-- Name: repos_alias_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX repos_alias_idx ON public.gha_repos USING btree (alias);


--
-- Name: repos_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX repos_name_idx ON public.gha_repos USING btree (name);


--
-- Name: repos_org_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX repos_org_id_idx ON public.gha_repos USING btree (org_id);


--
-- Name: repos_org_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX repos_org_login_idx ON public.gha_repos USING btree (org_login);


--
-- Name: repos_repo_group_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX repos_repo_group_idx ON public.gha_repos USING btree (repo_group);


--
-- Name: skip_commits_sha_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX skip_commits_sha_idx ON public.gha_skip_commits USING btree (sha);


--
-- Name: teams_dup_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX teams_dup_actor_id_idx ON public.gha_teams USING btree (dup_actor_id);


--
-- Name: teams_dup_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX teams_dup_actor_login_idx ON public.gha_teams USING btree (dup_actor_login);


--
-- Name: teams_dup_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX teams_dup_created_at_idx ON public.gha_teams USING btree (dup_created_at);


--
-- Name: teams_dup_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX teams_dup_repo_id_idx ON public.gha_teams USING btree (dup_repo_id);


--
-- Name: teams_dup_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX teams_dup_repo_name_idx ON public.gha_teams USING btree (dup_repo_name);


--
-- Name: teams_dup_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX teams_dup_type_idx ON public.gha_teams USING btree (dup_type);


--
-- Name: teams_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX teams_event_id_idx ON public.gha_teams USING btree (event_id);


--
-- Name: teams_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX teams_name_idx ON public.gha_teams USING btree (name);


--
-- Name: teams_permission_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX teams_permission_idx ON public.gha_teams USING btree (permission);


--
-- Name: teams_slug_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX teams_slug_idx ON public.gha_teams USING btree (slug);


--
-- Name: texts_actor_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX texts_actor_id_idx ON public.gha_texts USING btree (actor_id);


--
-- Name: texts_actor_login_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX texts_actor_login_idx ON public.gha_texts USING btree (actor_login);


--
-- Name: texts_created_at_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX texts_created_at_idx ON public.gha_texts USING btree (created_at);


--
-- Name: texts_event_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX texts_event_id_idx ON public.gha_texts USING btree (event_id);


--
-- Name: texts_repo_id_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX texts_repo_id_idx ON public.gha_texts USING btree (repo_id);


--
-- Name: texts_repo_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX texts_repo_name_idx ON public.gha_texts USING btree (repo_name);


--
-- Name: texts_type_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX texts_type_idx ON public.gha_texts USING btree (type);


--
-- Name: vars_name_idx; Type: INDEX; Schema: public; Owner: gha_admin
--

CREATE INDEX vars_name_idx ON public.gha_vars USING btree (name);


--
-- Name: SCHEMA current_state; Type: ACL; Schema: -; Owner: devstats_team
--

GRANT USAGE ON SCHEMA current_state TO gha_admin;


--
-- Name: TABLE gha_issues_labels; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_issues_labels TO ro_user;
GRANT SELECT ON TABLE public.gha_issues_labels TO devstats_team;


--
-- Name: TABLE issue_labels; Type: ACL; Schema: current_state; Owner: devstats_team
--

GRANT SELECT ON TABLE current_state.issue_labels TO gha_admin;


--
-- Name: TABLE gha_milestones; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_milestones TO ro_user;
GRANT SELECT ON TABLE public.gha_milestones TO devstats_team;


--
-- Name: TABLE milestones; Type: ACL; Schema: current_state; Owner: devstats_team
--

GRANT SELECT ON TABLE current_state.milestones TO gha_admin;


--
-- Name: TABLE gha_issues; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_issues TO ro_user;
GRANT SELECT ON TABLE public.gha_issues TO devstats_team;


--
-- Name: TABLE issues; Type: ACL; Schema: current_state; Owner: devstats_team
--

GRANT SELECT ON TABLE current_state.issues TO gha_admin;


--
-- Name: TABLE gha_pull_requests; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_pull_requests TO ro_user;
GRANT SELECT ON TABLE public.gha_pull_requests TO devstats_team;


--
-- Name: TABLE prs; Type: ACL; Schema: current_state; Owner: devstats_team
--

GRANT SELECT ON TABLE current_state.prs TO gha_admin;


--
-- Name: TABLE gha_actors; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_actors TO ro_user;
GRANT SELECT ON TABLE public.gha_actors TO devstats_team;


--
-- Name: TABLE gha_actors_affiliations; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_actors_affiliations TO ro_user;
GRANT SELECT ON TABLE public.gha_actors_affiliations TO devstats_team;


--
-- Name: TABLE gha_actors_emails; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_actors_emails TO ro_user;
GRANT SELECT ON TABLE public.gha_actors_emails TO devstats_team;


--
-- Name: TABLE gha_assets; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_assets TO ro_user;
GRANT SELECT ON TABLE public.gha_assets TO devstats_team;


--
-- Name: TABLE gha_branches; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_branches TO ro_user;
GRANT SELECT ON TABLE public.gha_branches TO devstats_team;


--
-- Name: TABLE gha_comments; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_comments TO ro_user;
GRANT SELECT ON TABLE public.gha_comments TO devstats_team;


--
-- Name: TABLE gha_commits; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_commits TO ro_user;
GRANT SELECT ON TABLE public.gha_commits TO devstats_team;


--
-- Name: TABLE gha_commits_files; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_commits_files TO ro_user;
GRANT SELECT ON TABLE public.gha_commits_files TO devstats_team;


--
-- Name: TABLE gha_companies; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_companies TO ro_user;
GRANT SELECT ON TABLE public.gha_companies TO devstats_team;


--
-- Name: TABLE gha_computed; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_computed TO ro_user;
GRANT SELECT ON TABLE public.gha_computed TO devstats_team;


--
-- Name: TABLE gha_events; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_events TO ro_user;
GRANT SELECT ON TABLE public.gha_events TO devstats_team;


--
-- Name: TABLE gha_events_commits_files; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_events_commits_files TO ro_user;
GRANT SELECT ON TABLE public.gha_events_commits_files TO devstats_team;


--
-- Name: TABLE gha_forkees; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_forkees TO ro_user;
GRANT SELECT ON TABLE public.gha_forkees TO devstats_team;


--
-- Name: TABLE gha_issues_assignees; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_issues_assignees TO ro_user;
GRANT SELECT ON TABLE public.gha_issues_assignees TO devstats_team;


--
-- Name: TABLE gha_issues_events_labels; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_issues_events_labels TO ro_user;
GRANT SELECT ON TABLE public.gha_issues_events_labels TO devstats_team;


--
-- Name: TABLE gha_issues_pull_requests; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_issues_pull_requests TO ro_user;
GRANT SELECT ON TABLE public.gha_issues_pull_requests TO devstats_team;


--
-- Name: TABLE gha_labels; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_labels TO ro_user;
GRANT SELECT ON TABLE public.gha_labels TO devstats_team;


--
-- Name: TABLE gha_logs; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_logs TO ro_user;
GRANT SELECT ON TABLE public.gha_logs TO devstats_team;


--
-- Name: TABLE gha_orgs; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_orgs TO ro_user;
GRANT SELECT ON TABLE public.gha_orgs TO devstats_team;


--
-- Name: TABLE gha_pages; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_pages TO ro_user;
GRANT SELECT ON TABLE public.gha_pages TO devstats_team;


--
-- Name: TABLE gha_parsed; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_parsed TO ro_user;
GRANT SELECT ON TABLE public.gha_parsed TO devstats_team;


--
-- Name: TABLE gha_payloads; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_payloads TO ro_user;
GRANT SELECT ON TABLE public.gha_payloads TO devstats_team;


--
-- Name: TABLE gha_postprocess_scripts; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_postprocess_scripts TO ro_user;
GRANT SELECT ON TABLE public.gha_postprocess_scripts TO devstats_team;


--
-- Name: TABLE gha_pull_requests_assignees; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_pull_requests_assignees TO ro_user;
GRANT SELECT ON TABLE public.gha_pull_requests_assignees TO devstats_team;


--
-- Name: TABLE gha_pull_requests_requested_reviewers; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_pull_requests_requested_reviewers TO ro_user;
GRANT SELECT ON TABLE public.gha_pull_requests_requested_reviewers TO devstats_team;


--
-- Name: TABLE gha_releases; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_releases TO ro_user;
GRANT SELECT ON TABLE public.gha_releases TO devstats_team;


--
-- Name: TABLE gha_releases_assets; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_releases_assets TO ro_user;
GRANT SELECT ON TABLE public.gha_releases_assets TO devstats_team;


--
-- Name: TABLE gha_repos; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_repos TO ro_user;
GRANT SELECT ON TABLE public.gha_repos TO devstats_team;


--
-- Name: TABLE gha_skip_commits; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_skip_commits TO ro_user;
GRANT SELECT ON TABLE public.gha_skip_commits TO devstats_team;


--
-- Name: TABLE gha_teams; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_teams TO ro_user;
GRANT SELECT ON TABLE public.gha_teams TO devstats_team;


--
-- Name: TABLE gha_teams_repositories; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_teams_repositories TO ro_user;
GRANT SELECT ON TABLE public.gha_teams_repositories TO devstats_team;


--
-- Name: TABLE gha_texts; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_texts TO ro_user;
GRANT SELECT ON TABLE public.gha_texts TO devstats_team;


--
-- Name: TABLE gha_vars; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.gha_vars TO ro_user;
GRANT SELECT ON TABLE public.gha_vars TO devstats_team;


--
-- Name: TABLE sannotations; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.sannotations TO ro_user;
GRANT SELECT ON TABLE public.sannotations TO devstats_team;


--
-- Name: TABLE sbot_commands; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.sbot_commands TO ro_user;
GRANT SELECT ON TABLE public.sbot_commands TO devstats_team;


--
-- Name: TABLE scompany_activity; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.scompany_activity TO ro_user;
GRANT SELECT ON TABLE public.scompany_activity TO devstats_team;


--
-- Name: TABLE sepisodic_contributors; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.sepisodic_contributors TO ro_user;
GRANT SELECT ON TABLE public.sepisodic_contributors TO devstats_team;


--
-- Name: TABLE sepisodic_issues; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.sepisodic_issues TO ro_user;
GRANT SELECT ON TABLE public.sepisodic_issues TO devstats_team;


--
-- Name: TABLE sevents_h; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.sevents_h TO ro_user;
GRANT SELECT ON TABLE public.sevents_h TO devstats_team;


--
-- Name: TABLE sfirst_non_author; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.sfirst_non_author TO ro_user;
GRANT SELECT ON TABLE public.sfirst_non_author TO devstats_team;


--
-- Name: TABLE sgh_stats_r; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.sgh_stats_r TO ro_user;
GRANT SELECT ON TABLE public.sgh_stats_r TO devstats_team;


--
-- Name: TABLE sgh_stats_rgrp; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.sgh_stats_rgrp TO ro_user;
GRANT SELECT ON TABLE public.sgh_stats_rgrp TO devstats_team;


--
-- Name: TABLE shcomcommenters; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shcomcommenters TO ro_user;
GRANT SELECT ON TABLE public.shcomcommenters TO devstats_team;


--
-- Name: TABLE shcomcomments; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shcomcomments TO ro_user;
GRANT SELECT ON TABLE public.shcomcomments TO devstats_team;


--
-- Name: TABLE shcomcommitcommenters; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shcomcommitcommenters TO ro_user;
GRANT SELECT ON TABLE public.shcomcommitcommenters TO devstats_team;


--
-- Name: TABLE shcomcommits; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shcomcommits TO ro_user;
GRANT SELECT ON TABLE public.shcomcommits TO devstats_team;


--
-- Name: TABLE shcomcommitters; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shcomcommitters TO ro_user;
GRANT SELECT ON TABLE public.shcomcommitters TO devstats_team;


--
-- Name: TABLE shcomcontributions; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shcomcontributions TO ro_user;
GRANT SELECT ON TABLE public.shcomcontributions TO devstats_team;


--
-- Name: TABLE shcomcontributors; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shcomcontributors TO ro_user;
GRANT SELECT ON TABLE public.shcomcontributors TO devstats_team;


--
-- Name: TABLE shcomevents; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shcomevents TO ro_user;
GRANT SELECT ON TABLE public.shcomevents TO devstats_team;


--
-- Name: TABLE shcomforkers; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shcomforkers TO ro_user;
GRANT SELECT ON TABLE public.shcomforkers TO devstats_team;


--
-- Name: TABLE shcomissuecommenters; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shcomissuecommenters TO ro_user;
GRANT SELECT ON TABLE public.shcomissuecommenters TO devstats_team;


--
-- Name: TABLE shcomissuecreators; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shcomissuecreators TO ro_user;
GRANT SELECT ON TABLE public.shcomissuecreators TO devstats_team;


--
-- Name: TABLE shcomissues; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shcomissues TO ro_user;
GRANT SELECT ON TABLE public.shcomissues TO devstats_team;


--
-- Name: TABLE shcomprcreators; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shcomprcreators TO ro_user;
GRANT SELECT ON TABLE public.shcomprcreators TO devstats_team;


--
-- Name: TABLE shcomprreviewers; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shcomprreviewers TO ro_user;
GRANT SELECT ON TABLE public.shcomprreviewers TO devstats_team;


--
-- Name: TABLE shcomprs; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shcomprs TO ro_user;
GRANT SELECT ON TABLE public.shcomprs TO devstats_team;


--
-- Name: TABLE shcomrepositories; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shcomrepositories TO ro_user;
GRANT SELECT ON TABLE public.shcomrepositories TO devstats_team;


--
-- Name: TABLE shcomwatchers; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shcomwatchers TO ro_user;
GRANT SELECT ON TABLE public.shcomwatchers TO devstats_team;


--
-- Name: TABLE shdev_active_reposall; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_active_reposall TO ro_user;
GRANT SELECT ON TABLE public.shdev_active_reposall TO devstats_team;


--
-- Name: TABLE shdev_active_reposapimachinery; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_active_reposapimachinery TO ro_user;
GRANT SELECT ON TABLE public.shdev_active_reposapimachinery TO devstats_team;


--
-- Name: TABLE shdev_active_reposapps; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_active_reposapps TO ro_user;
GRANT SELECT ON TABLE public.shdev_active_reposapps TO devstats_team;


--
-- Name: TABLE shdev_active_reposautoscalingandmonitoring; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_active_reposautoscalingandmonitoring TO ro_user;
GRANT SELECT ON TABLE public.shdev_active_reposautoscalingandmonitoring TO devstats_team;


--
-- Name: TABLE shdev_active_reposclients; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_active_reposclients TO ro_user;
GRANT SELECT ON TABLE public.shdev_active_reposclients TO devstats_team;


--
-- Name: TABLE shdev_active_reposclusterlifecycle; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_active_reposclusterlifecycle TO ro_user;
GRANT SELECT ON TABLE public.shdev_active_reposclusterlifecycle TO devstats_team;


--
-- Name: TABLE shdev_active_reposcsi; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_active_reposcsi TO ro_user;
GRANT SELECT ON TABLE public.shdev_active_reposcsi TO devstats_team;


--
-- Name: TABLE shdev_active_reposdocs; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_active_reposdocs TO ro_user;
GRANT SELECT ON TABLE public.shdev_active_reposdocs TO devstats_team;


--
-- Name: TABLE shdev_active_reposkubernetes; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_active_reposkubernetes TO ro_user;
GRANT SELECT ON TABLE public.shdev_active_reposkubernetes TO devstats_team;


--
-- Name: TABLE shdev_active_reposmisc; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_active_reposmisc TO ro_user;
GRANT SELECT ON TABLE public.shdev_active_reposmisc TO devstats_team;


--
-- Name: TABLE shdev_active_reposnetworking; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_active_reposnetworking TO ro_user;
GRANT SELECT ON TABLE public.shdev_active_reposnetworking TO devstats_team;


--
-- Name: TABLE shdev_active_reposnode; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_active_reposnode TO ro_user;
GRANT SELECT ON TABLE public.shdev_active_reposnode TO devstats_team;


--
-- Name: TABLE shdev_active_reposproject; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_active_reposproject TO ro_user;
GRANT SELECT ON TABLE public.shdev_active_reposproject TO devstats_team;


--
-- Name: TABLE shdev_active_reposprojectinfra; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_active_reposprojectinfra TO ro_user;
GRANT SELECT ON TABLE public.shdev_active_reposprojectinfra TO devstats_team;


--
-- Name: TABLE shdev_active_reposstorage; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_active_reposstorage TO ro_user;
GRANT SELECT ON TABLE public.shdev_active_reposstorage TO devstats_team;


--
-- Name: TABLE shdev_active_reposui; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_active_reposui TO ro_user;
GRANT SELECT ON TABLE public.shdev_active_reposui TO devstats_team;


--
-- Name: TABLE shdev_approvesall; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_approvesall TO ro_user;
GRANT SELECT ON TABLE public.shdev_approvesall TO devstats_team;


--
-- Name: TABLE shdev_approvesapimachinery; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_approvesapimachinery TO ro_user;
GRANT SELECT ON TABLE public.shdev_approvesapimachinery TO devstats_team;


--
-- Name: TABLE shdev_approvesapps; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_approvesapps TO ro_user;
GRANT SELECT ON TABLE public.shdev_approvesapps TO devstats_team;


--
-- Name: TABLE shdev_approvesautoscalingandmonitoring; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_approvesautoscalingandmonitoring TO ro_user;
GRANT SELECT ON TABLE public.shdev_approvesautoscalingandmonitoring TO devstats_team;


--
-- Name: TABLE shdev_approvesclients; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_approvesclients TO ro_user;
GRANT SELECT ON TABLE public.shdev_approvesclients TO devstats_team;


--
-- Name: TABLE shdev_approvesclusterlifecycle; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_approvesclusterlifecycle TO ro_user;
GRANT SELECT ON TABLE public.shdev_approvesclusterlifecycle TO devstats_team;


--
-- Name: TABLE shdev_approvescontrib; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_approvescontrib TO ro_user;
GRANT SELECT ON TABLE public.shdev_approvescontrib TO devstats_team;


--
-- Name: TABLE shdev_approvescsi; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_approvescsi TO ro_user;
GRANT SELECT ON TABLE public.shdev_approvescsi TO devstats_team;


--
-- Name: TABLE shdev_approvesdocs; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_approvesdocs TO ro_user;
GRANT SELECT ON TABLE public.shdev_approvesdocs TO devstats_team;


--
-- Name: TABLE shdev_approveskubernetes; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_approveskubernetes TO ro_user;
GRANT SELECT ON TABLE public.shdev_approveskubernetes TO devstats_team;


--
-- Name: TABLE shdev_approvesmisc; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_approvesmisc TO ro_user;
GRANT SELECT ON TABLE public.shdev_approvesmisc TO devstats_team;


--
-- Name: TABLE shdev_approvesmulticluster; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_approvesmulticluster TO ro_user;
GRANT SELECT ON TABLE public.shdev_approvesmulticluster TO devstats_team;


--
-- Name: TABLE shdev_approvesnetworking; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_approvesnetworking TO ro_user;
GRANT SELECT ON TABLE public.shdev_approvesnetworking TO devstats_team;


--
-- Name: TABLE shdev_approvesnode; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_approvesnode TO ro_user;
GRANT SELECT ON TABLE public.shdev_approvesnode TO devstats_team;


--
-- Name: TABLE shdev_approvesproject; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_approvesproject TO ro_user;
GRANT SELECT ON TABLE public.shdev_approvesproject TO devstats_team;


--
-- Name: TABLE shdev_approvesprojectinfra; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_approvesprojectinfra TO ro_user;
GRANT SELECT ON TABLE public.shdev_approvesprojectinfra TO devstats_team;


--
-- Name: TABLE shdev_approvessigservicecatalog; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_approvessigservicecatalog TO ro_user;
GRANT SELECT ON TABLE public.shdev_approvessigservicecatalog TO devstats_team;


--
-- Name: TABLE shdev_approvesstorage; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_approvesstorage TO ro_user;
GRANT SELECT ON TABLE public.shdev_approvesstorage TO devstats_team;


--
-- Name: TABLE shdev_approvesui; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_approvesui TO ro_user;
GRANT SELECT ON TABLE public.shdev_approvesui TO devstats_team;


--
-- Name: TABLE shdev_commentsall; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commentsall TO ro_user;
GRANT SELECT ON TABLE public.shdev_commentsall TO devstats_team;


--
-- Name: TABLE shdev_commentsapimachinery; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commentsapimachinery TO ro_user;
GRANT SELECT ON TABLE public.shdev_commentsapimachinery TO devstats_team;


--
-- Name: TABLE shdev_commentsapps; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commentsapps TO ro_user;
GRANT SELECT ON TABLE public.shdev_commentsapps TO devstats_team;


--
-- Name: TABLE shdev_commentsautoscalingandmonitoring; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commentsautoscalingandmonitoring TO ro_user;
GRANT SELECT ON TABLE public.shdev_commentsautoscalingandmonitoring TO devstats_team;


--
-- Name: TABLE shdev_commentsclients; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commentsclients TO ro_user;
GRANT SELECT ON TABLE public.shdev_commentsclients TO devstats_team;


--
-- Name: TABLE shdev_commentsclusterlifecycle; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commentsclusterlifecycle TO ro_user;
GRANT SELECT ON TABLE public.shdev_commentsclusterlifecycle TO devstats_team;


--
-- Name: TABLE shdev_commentscontrib; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commentscontrib TO ro_user;
GRANT SELECT ON TABLE public.shdev_commentscontrib TO devstats_team;


--
-- Name: TABLE shdev_commentscsi; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commentscsi TO ro_user;
GRANT SELECT ON TABLE public.shdev_commentscsi TO devstats_team;


--
-- Name: TABLE shdev_commentsdocs; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commentsdocs TO ro_user;
GRANT SELECT ON TABLE public.shdev_commentsdocs TO devstats_team;


--
-- Name: TABLE shdev_commentskubernetes; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commentskubernetes TO ro_user;
GRANT SELECT ON TABLE public.shdev_commentskubernetes TO devstats_team;


--
-- Name: TABLE shdev_commentsmisc; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commentsmisc TO ro_user;
GRANT SELECT ON TABLE public.shdev_commentsmisc TO devstats_team;


--
-- Name: TABLE shdev_commentsmulticluster; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commentsmulticluster TO ro_user;
GRANT SELECT ON TABLE public.shdev_commentsmulticluster TO devstats_team;


--
-- Name: TABLE shdev_commentsnetworking; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commentsnetworking TO ro_user;
GRANT SELECT ON TABLE public.shdev_commentsnetworking TO devstats_team;


--
-- Name: TABLE shdev_commentsnode; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commentsnode TO ro_user;
GRANT SELECT ON TABLE public.shdev_commentsnode TO devstats_team;


--
-- Name: TABLE shdev_commentsproject; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commentsproject TO ro_user;
GRANT SELECT ON TABLE public.shdev_commentsproject TO devstats_team;


--
-- Name: TABLE shdev_commentsprojectinfra; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commentsprojectinfra TO ro_user;
GRANT SELECT ON TABLE public.shdev_commentsprojectinfra TO devstats_team;


--
-- Name: TABLE shdev_commentssigservicecatalog; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commentssigservicecatalog TO ro_user;
GRANT SELECT ON TABLE public.shdev_commentssigservicecatalog TO devstats_team;


--
-- Name: TABLE shdev_commentsstorage; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commentsstorage TO ro_user;
GRANT SELECT ON TABLE public.shdev_commentsstorage TO devstats_team;


--
-- Name: TABLE shdev_commentsui; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commentsui TO ro_user;
GRANT SELECT ON TABLE public.shdev_commentsui TO devstats_team;


--
-- Name: TABLE shdev_commit_commentsall; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commit_commentsall TO ro_user;
GRANT SELECT ON TABLE public.shdev_commit_commentsall TO devstats_team;


--
-- Name: TABLE shdev_commit_commentsapps; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commit_commentsapps TO ro_user;
GRANT SELECT ON TABLE public.shdev_commit_commentsapps TO devstats_team;


--
-- Name: TABLE shdev_commit_commentsautoscalingandmonitoring; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commit_commentsautoscalingandmonitoring TO ro_user;
GRANT SELECT ON TABLE public.shdev_commit_commentsautoscalingandmonitoring TO devstats_team;


--
-- Name: TABLE shdev_commit_commentsclients; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commit_commentsclients TO ro_user;
GRANT SELECT ON TABLE public.shdev_commit_commentsclients TO devstats_team;


--
-- Name: TABLE shdev_commit_commentsclusterlifecycle; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commit_commentsclusterlifecycle TO ro_user;
GRANT SELECT ON TABLE public.shdev_commit_commentsclusterlifecycle TO devstats_team;


--
-- Name: TABLE shdev_commit_commentscontrib; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commit_commentscontrib TO ro_user;
GRANT SELECT ON TABLE public.shdev_commit_commentscontrib TO devstats_team;


--
-- Name: TABLE shdev_commit_commentscsi; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commit_commentscsi TO ro_user;
GRANT SELECT ON TABLE public.shdev_commit_commentscsi TO devstats_team;


--
-- Name: TABLE shdev_commit_commentsdocs; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commit_commentsdocs TO ro_user;
GRANT SELECT ON TABLE public.shdev_commit_commentsdocs TO devstats_team;


--
-- Name: TABLE shdev_commit_commentskubernetes; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commit_commentskubernetes TO ro_user;
GRANT SELECT ON TABLE public.shdev_commit_commentskubernetes TO devstats_team;


--
-- Name: TABLE shdev_commit_commentsmisc; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commit_commentsmisc TO ro_user;
GRANT SELECT ON TABLE public.shdev_commit_commentsmisc TO devstats_team;


--
-- Name: TABLE shdev_commit_commentsnetworking; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commit_commentsnetworking TO ro_user;
GRANT SELECT ON TABLE public.shdev_commit_commentsnetworking TO devstats_team;


--
-- Name: TABLE shdev_commit_commentsnode; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commit_commentsnode TO ro_user;
GRANT SELECT ON TABLE public.shdev_commit_commentsnode TO devstats_team;


--
-- Name: TABLE shdev_commit_commentsproject; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commit_commentsproject TO ro_user;
GRANT SELECT ON TABLE public.shdev_commit_commentsproject TO devstats_team;


--
-- Name: TABLE shdev_commit_commentsprojectinfra; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commit_commentsprojectinfra TO ro_user;
GRANT SELECT ON TABLE public.shdev_commit_commentsprojectinfra TO devstats_team;


--
-- Name: TABLE shdev_commit_commentssigservicecatalog; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commit_commentssigservicecatalog TO ro_user;
GRANT SELECT ON TABLE public.shdev_commit_commentssigservicecatalog TO devstats_team;


--
-- Name: TABLE shdev_commit_commentsstorage; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commit_commentsstorage TO ro_user;
GRANT SELECT ON TABLE public.shdev_commit_commentsstorage TO devstats_team;


--
-- Name: TABLE shdev_commit_commentsui; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commit_commentsui TO ro_user;
GRANT SELECT ON TABLE public.shdev_commit_commentsui TO devstats_team;


--
-- Name: TABLE shdev_commitsall; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commitsall TO ro_user;
GRANT SELECT ON TABLE public.shdev_commitsall TO devstats_team;


--
-- Name: TABLE shdev_commitsapimachinery; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commitsapimachinery TO ro_user;
GRANT SELECT ON TABLE public.shdev_commitsapimachinery TO devstats_team;


--
-- Name: TABLE shdev_commitsapps; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commitsapps TO ro_user;
GRANT SELECT ON TABLE public.shdev_commitsapps TO devstats_team;


--
-- Name: TABLE shdev_commitsautoscalingandmonitoring; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commitsautoscalingandmonitoring TO ro_user;
GRANT SELECT ON TABLE public.shdev_commitsautoscalingandmonitoring TO devstats_team;


--
-- Name: TABLE shdev_commitsclients; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commitsclients TO ro_user;
GRANT SELECT ON TABLE public.shdev_commitsclients TO devstats_team;


--
-- Name: TABLE shdev_commitsclusterlifecycle; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commitsclusterlifecycle TO ro_user;
GRANT SELECT ON TABLE public.shdev_commitsclusterlifecycle TO devstats_team;


--
-- Name: TABLE shdev_commitscontrib; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commitscontrib TO ro_user;
GRANT SELECT ON TABLE public.shdev_commitscontrib TO devstats_team;


--
-- Name: TABLE shdev_commitscsi; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commitscsi TO ro_user;
GRANT SELECT ON TABLE public.shdev_commitscsi TO devstats_team;


--
-- Name: TABLE shdev_commitsdocs; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commitsdocs TO ro_user;
GRANT SELECT ON TABLE public.shdev_commitsdocs TO devstats_team;


--
-- Name: TABLE shdev_commitskubernetes; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commitskubernetes TO ro_user;
GRANT SELECT ON TABLE public.shdev_commitskubernetes TO devstats_team;


--
-- Name: TABLE shdev_commitsmisc; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commitsmisc TO ro_user;
GRANT SELECT ON TABLE public.shdev_commitsmisc TO devstats_team;


--
-- Name: TABLE shdev_commitsmulticluster; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commitsmulticluster TO ro_user;
GRANT SELECT ON TABLE public.shdev_commitsmulticluster TO devstats_team;


--
-- Name: TABLE shdev_commitsnetworking; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commitsnetworking TO ro_user;
GRANT SELECT ON TABLE public.shdev_commitsnetworking TO devstats_team;


--
-- Name: TABLE shdev_commitsnode; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commitsnode TO ro_user;
GRANT SELECT ON TABLE public.shdev_commitsnode TO devstats_team;


--
-- Name: TABLE shdev_commitsproject; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commitsproject TO ro_user;
GRANT SELECT ON TABLE public.shdev_commitsproject TO devstats_team;


--
-- Name: TABLE shdev_commitsprojectinfra; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commitsprojectinfra TO ro_user;
GRANT SELECT ON TABLE public.shdev_commitsprojectinfra TO devstats_team;


--
-- Name: TABLE shdev_commitssigservicecatalog; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commitssigservicecatalog TO ro_user;
GRANT SELECT ON TABLE public.shdev_commitssigservicecatalog TO devstats_team;


--
-- Name: TABLE shdev_commitsstorage; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commitsstorage TO ro_user;
GRANT SELECT ON TABLE public.shdev_commitsstorage TO devstats_team;


--
-- Name: TABLE shdev_commitsui; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_commitsui TO ro_user;
GRANT SELECT ON TABLE public.shdev_commitsui TO devstats_team;


--
-- Name: TABLE shdev_contributionsall; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_contributionsall TO ro_user;
GRANT SELECT ON TABLE public.shdev_contributionsall TO devstats_team;


--
-- Name: TABLE shdev_contributionsapimachinery; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_contributionsapimachinery TO ro_user;
GRANT SELECT ON TABLE public.shdev_contributionsapimachinery TO devstats_team;


--
-- Name: TABLE shdev_contributionsapps; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_contributionsapps TO ro_user;
GRANT SELECT ON TABLE public.shdev_contributionsapps TO devstats_team;


--
-- Name: TABLE shdev_contributionsautoscalingandmonitoring; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_contributionsautoscalingandmonitoring TO ro_user;
GRANT SELECT ON TABLE public.shdev_contributionsautoscalingandmonitoring TO devstats_team;


--
-- Name: TABLE shdev_contributionsclients; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_contributionsclients TO ro_user;
GRANT SELECT ON TABLE public.shdev_contributionsclients TO devstats_team;


--
-- Name: TABLE shdev_contributionsclusterlifecycle; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_contributionsclusterlifecycle TO ro_user;
GRANT SELECT ON TABLE public.shdev_contributionsclusterlifecycle TO devstats_team;


--
-- Name: TABLE shdev_contributionscontrib; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_contributionscontrib TO ro_user;
GRANT SELECT ON TABLE public.shdev_contributionscontrib TO devstats_team;


--
-- Name: TABLE shdev_contributionscsi; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_contributionscsi TO ro_user;
GRANT SELECT ON TABLE public.shdev_contributionscsi TO devstats_team;


--
-- Name: TABLE shdev_contributionsdocs; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_contributionsdocs TO ro_user;
GRANT SELECT ON TABLE public.shdev_contributionsdocs TO devstats_team;


--
-- Name: TABLE shdev_contributionskubernetes; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_contributionskubernetes TO ro_user;
GRANT SELECT ON TABLE public.shdev_contributionskubernetes TO devstats_team;


--
-- Name: TABLE shdev_contributionsmisc; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_contributionsmisc TO ro_user;
GRANT SELECT ON TABLE public.shdev_contributionsmisc TO devstats_team;


--
-- Name: TABLE shdev_contributionsmulticluster; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_contributionsmulticluster TO ro_user;
GRANT SELECT ON TABLE public.shdev_contributionsmulticluster TO devstats_team;


--
-- Name: TABLE shdev_contributionsnetworking; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_contributionsnetworking TO ro_user;
GRANT SELECT ON TABLE public.shdev_contributionsnetworking TO devstats_team;


--
-- Name: TABLE shdev_contributionsnode; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_contributionsnode TO ro_user;
GRANT SELECT ON TABLE public.shdev_contributionsnode TO devstats_team;


--
-- Name: TABLE shdev_contributionsproject; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_contributionsproject TO ro_user;
GRANT SELECT ON TABLE public.shdev_contributionsproject TO devstats_team;


--
-- Name: TABLE shdev_contributionsprojectinfra; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_contributionsprojectinfra TO ro_user;
GRANT SELECT ON TABLE public.shdev_contributionsprojectinfra TO devstats_team;


--
-- Name: TABLE shdev_contributionssigservicecatalog; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_contributionssigservicecatalog TO ro_user;
GRANT SELECT ON TABLE public.shdev_contributionssigservicecatalog TO devstats_team;


--
-- Name: TABLE shdev_contributionsstorage; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_contributionsstorage TO ro_user;
GRANT SELECT ON TABLE public.shdev_contributionsstorage TO devstats_team;


--
-- Name: TABLE shdev_contributionsui; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_contributionsui TO ro_user;
GRANT SELECT ON TABLE public.shdev_contributionsui TO devstats_team;


--
-- Name: TABLE shdev_eventsall; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_eventsall TO ro_user;
GRANT SELECT ON TABLE public.shdev_eventsall TO devstats_team;


--
-- Name: TABLE shdev_eventsapimachinery; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_eventsapimachinery TO ro_user;
GRANT SELECT ON TABLE public.shdev_eventsapimachinery TO devstats_team;


--
-- Name: TABLE shdev_eventsapps; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_eventsapps TO ro_user;
GRANT SELECT ON TABLE public.shdev_eventsapps TO devstats_team;


--
-- Name: TABLE shdev_eventsautoscalingandmonitoring; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_eventsautoscalingandmonitoring TO ro_user;
GRANT SELECT ON TABLE public.shdev_eventsautoscalingandmonitoring TO devstats_team;


--
-- Name: TABLE shdev_eventsclients; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_eventsclients TO ro_user;
GRANT SELECT ON TABLE public.shdev_eventsclients TO devstats_team;


--
-- Name: TABLE shdev_eventsclusterlifecycle; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_eventsclusterlifecycle TO ro_user;
GRANT SELECT ON TABLE public.shdev_eventsclusterlifecycle TO devstats_team;


--
-- Name: TABLE shdev_eventscontrib; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_eventscontrib TO ro_user;
GRANT SELECT ON TABLE public.shdev_eventscontrib TO devstats_team;


--
-- Name: TABLE shdev_eventscsi; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_eventscsi TO ro_user;
GRANT SELECT ON TABLE public.shdev_eventscsi TO devstats_team;


--
-- Name: TABLE shdev_eventsdocs; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_eventsdocs TO ro_user;
GRANT SELECT ON TABLE public.shdev_eventsdocs TO devstats_team;


--
-- Name: TABLE shdev_eventskubernetes; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_eventskubernetes TO ro_user;
GRANT SELECT ON TABLE public.shdev_eventskubernetes TO devstats_team;


--
-- Name: TABLE shdev_eventsmisc; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_eventsmisc TO ro_user;
GRANT SELECT ON TABLE public.shdev_eventsmisc TO devstats_team;


--
-- Name: TABLE shdev_eventsmulticluster; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_eventsmulticluster TO ro_user;
GRANT SELECT ON TABLE public.shdev_eventsmulticluster TO devstats_team;


--
-- Name: TABLE shdev_eventsnetworking; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_eventsnetworking TO ro_user;
GRANT SELECT ON TABLE public.shdev_eventsnetworking TO devstats_team;


--
-- Name: TABLE shdev_eventsnode; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_eventsnode TO ro_user;
GRANT SELECT ON TABLE public.shdev_eventsnode TO devstats_team;


--
-- Name: TABLE shdev_eventsproject; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_eventsproject TO ro_user;
GRANT SELECT ON TABLE public.shdev_eventsproject TO devstats_team;


--
-- Name: TABLE shdev_eventsprojectinfra; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_eventsprojectinfra TO ro_user;
GRANT SELECT ON TABLE public.shdev_eventsprojectinfra TO devstats_team;


--
-- Name: TABLE shdev_eventssigservicecatalog; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_eventssigservicecatalog TO ro_user;
GRANT SELECT ON TABLE public.shdev_eventssigservicecatalog TO devstats_team;


--
-- Name: TABLE shdev_eventsstorage; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_eventsstorage TO ro_user;
GRANT SELECT ON TABLE public.shdev_eventsstorage TO devstats_team;


--
-- Name: TABLE shdev_eventsui; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_eventsui TO ro_user;
GRANT SELECT ON TABLE public.shdev_eventsui TO devstats_team;


--
-- Name: TABLE shdev_issue_commentsall; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issue_commentsall TO ro_user;
GRANT SELECT ON TABLE public.shdev_issue_commentsall TO devstats_team;


--
-- Name: TABLE shdev_issue_commentsapimachinery; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issue_commentsapimachinery TO ro_user;
GRANT SELECT ON TABLE public.shdev_issue_commentsapimachinery TO devstats_team;


--
-- Name: TABLE shdev_issue_commentsapps; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issue_commentsapps TO ro_user;
GRANT SELECT ON TABLE public.shdev_issue_commentsapps TO devstats_team;


--
-- Name: TABLE shdev_issue_commentsautoscalingandmonitoring; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issue_commentsautoscalingandmonitoring TO ro_user;
GRANT SELECT ON TABLE public.shdev_issue_commentsautoscalingandmonitoring TO devstats_team;


--
-- Name: TABLE shdev_issue_commentsclients; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issue_commentsclients TO ro_user;
GRANT SELECT ON TABLE public.shdev_issue_commentsclients TO devstats_team;


--
-- Name: TABLE shdev_issue_commentsclusterlifecycle; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issue_commentsclusterlifecycle TO ro_user;
GRANT SELECT ON TABLE public.shdev_issue_commentsclusterlifecycle TO devstats_team;


--
-- Name: TABLE shdev_issue_commentscontrib; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issue_commentscontrib TO ro_user;
GRANT SELECT ON TABLE public.shdev_issue_commentscontrib TO devstats_team;


--
-- Name: TABLE shdev_issue_commentscsi; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issue_commentscsi TO ro_user;
GRANT SELECT ON TABLE public.shdev_issue_commentscsi TO devstats_team;


--
-- Name: TABLE shdev_issue_commentsdocs; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issue_commentsdocs TO ro_user;
GRANT SELECT ON TABLE public.shdev_issue_commentsdocs TO devstats_team;


--
-- Name: TABLE shdev_issue_commentskubernetes; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issue_commentskubernetes TO ro_user;
GRANT SELECT ON TABLE public.shdev_issue_commentskubernetes TO devstats_team;


--
-- Name: TABLE shdev_issue_commentsmisc; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issue_commentsmisc TO ro_user;
GRANT SELECT ON TABLE public.shdev_issue_commentsmisc TO devstats_team;


--
-- Name: TABLE shdev_issue_commentsmulticluster; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issue_commentsmulticluster TO ro_user;
GRANT SELECT ON TABLE public.shdev_issue_commentsmulticluster TO devstats_team;


--
-- Name: TABLE shdev_issue_commentsnetworking; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issue_commentsnetworking TO ro_user;
GRANT SELECT ON TABLE public.shdev_issue_commentsnetworking TO devstats_team;


--
-- Name: TABLE shdev_issue_commentsnode; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issue_commentsnode TO ro_user;
GRANT SELECT ON TABLE public.shdev_issue_commentsnode TO devstats_team;


--
-- Name: TABLE shdev_issue_commentsproject; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issue_commentsproject TO ro_user;
GRANT SELECT ON TABLE public.shdev_issue_commentsproject TO devstats_team;


--
-- Name: TABLE shdev_issue_commentsprojectinfra; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issue_commentsprojectinfra TO ro_user;
GRANT SELECT ON TABLE public.shdev_issue_commentsprojectinfra TO devstats_team;


--
-- Name: TABLE shdev_issue_commentssigservicecatalog; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issue_commentssigservicecatalog TO ro_user;
GRANT SELECT ON TABLE public.shdev_issue_commentssigservicecatalog TO devstats_team;


--
-- Name: TABLE shdev_issue_commentsstorage; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issue_commentsstorage TO ro_user;
GRANT SELECT ON TABLE public.shdev_issue_commentsstorage TO devstats_team;


--
-- Name: TABLE shdev_issue_commentsui; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issue_commentsui TO ro_user;
GRANT SELECT ON TABLE public.shdev_issue_commentsui TO devstats_team;


--
-- Name: TABLE shdev_issuesall; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issuesall TO ro_user;
GRANT SELECT ON TABLE public.shdev_issuesall TO devstats_team;


--
-- Name: TABLE shdev_issuesapimachinery; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issuesapimachinery TO ro_user;
GRANT SELECT ON TABLE public.shdev_issuesapimachinery TO devstats_team;


--
-- Name: TABLE shdev_issuesapps; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issuesapps TO ro_user;
GRANT SELECT ON TABLE public.shdev_issuesapps TO devstats_team;


--
-- Name: TABLE shdev_issuesautoscalingandmonitoring; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issuesautoscalingandmonitoring TO ro_user;
GRANT SELECT ON TABLE public.shdev_issuesautoscalingandmonitoring TO devstats_team;


--
-- Name: TABLE shdev_issuesclients; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issuesclients TO ro_user;
GRANT SELECT ON TABLE public.shdev_issuesclients TO devstats_team;


--
-- Name: TABLE shdev_issuesclusterlifecycle; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issuesclusterlifecycle TO ro_user;
GRANT SELECT ON TABLE public.shdev_issuesclusterlifecycle TO devstats_team;


--
-- Name: TABLE shdev_issuescontrib; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issuescontrib TO ro_user;
GRANT SELECT ON TABLE public.shdev_issuescontrib TO devstats_team;


--
-- Name: TABLE shdev_issuescsi; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issuescsi TO ro_user;
GRANT SELECT ON TABLE public.shdev_issuescsi TO devstats_team;


--
-- Name: TABLE shdev_issuesdocs; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issuesdocs TO ro_user;
GRANT SELECT ON TABLE public.shdev_issuesdocs TO devstats_team;


--
-- Name: TABLE shdev_issueskubernetes; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issueskubernetes TO ro_user;
GRANT SELECT ON TABLE public.shdev_issueskubernetes TO devstats_team;


--
-- Name: TABLE shdev_issuesmisc; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issuesmisc TO ro_user;
GRANT SELECT ON TABLE public.shdev_issuesmisc TO devstats_team;


--
-- Name: TABLE shdev_issuesmulticluster; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issuesmulticluster TO ro_user;
GRANT SELECT ON TABLE public.shdev_issuesmulticluster TO devstats_team;


--
-- Name: TABLE shdev_issuesnetworking; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issuesnetworking TO ro_user;
GRANT SELECT ON TABLE public.shdev_issuesnetworking TO devstats_team;


--
-- Name: TABLE shdev_issuesnode; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issuesnode TO ro_user;
GRANT SELECT ON TABLE public.shdev_issuesnode TO devstats_team;


--
-- Name: TABLE shdev_issuesproject; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issuesproject TO ro_user;
GRANT SELECT ON TABLE public.shdev_issuesproject TO devstats_team;


--
-- Name: TABLE shdev_issuesprojectinfra; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issuesprojectinfra TO ro_user;
GRANT SELECT ON TABLE public.shdev_issuesprojectinfra TO devstats_team;


--
-- Name: TABLE shdev_issuessigservicecatalog; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issuessigservicecatalog TO ro_user;
GRANT SELECT ON TABLE public.shdev_issuessigservicecatalog TO devstats_team;


--
-- Name: TABLE shdev_issuesstorage; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issuesstorage TO ro_user;
GRANT SELECT ON TABLE public.shdev_issuesstorage TO devstats_team;


--
-- Name: TABLE shdev_issuesui; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_issuesui TO ro_user;
GRANT SELECT ON TABLE public.shdev_issuesui TO devstats_team;


--
-- Name: TABLE shdev_prsall; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_prsall TO ro_user;
GRANT SELECT ON TABLE public.shdev_prsall TO devstats_team;


--
-- Name: TABLE shdev_prsapimachinery; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_prsapimachinery TO ro_user;
GRANT SELECT ON TABLE public.shdev_prsapimachinery TO devstats_team;


--
-- Name: TABLE shdev_prsapps; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_prsapps TO ro_user;
GRANT SELECT ON TABLE public.shdev_prsapps TO devstats_team;


--
-- Name: TABLE shdev_prsautoscalingandmonitoring; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_prsautoscalingandmonitoring TO ro_user;
GRANT SELECT ON TABLE public.shdev_prsautoscalingandmonitoring TO devstats_team;


--
-- Name: TABLE shdev_prsclients; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_prsclients TO ro_user;
GRANT SELECT ON TABLE public.shdev_prsclients TO devstats_team;


--
-- Name: TABLE shdev_prsclusterlifecycle; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_prsclusterlifecycle TO ro_user;
GRANT SELECT ON TABLE public.shdev_prsclusterlifecycle TO devstats_team;


--
-- Name: TABLE shdev_prscontrib; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_prscontrib TO ro_user;
GRANT SELECT ON TABLE public.shdev_prscontrib TO devstats_team;


--
-- Name: TABLE shdev_prscsi; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_prscsi TO ro_user;
GRANT SELECT ON TABLE public.shdev_prscsi TO devstats_team;


--
-- Name: TABLE shdev_prsdocs; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_prsdocs TO ro_user;
GRANT SELECT ON TABLE public.shdev_prsdocs TO devstats_team;


--
-- Name: TABLE shdev_prskubernetes; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_prskubernetes TO ro_user;
GRANT SELECT ON TABLE public.shdev_prskubernetes TO devstats_team;


--
-- Name: TABLE shdev_prsmisc; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_prsmisc TO ro_user;
GRANT SELECT ON TABLE public.shdev_prsmisc TO devstats_team;


--
-- Name: TABLE shdev_prsmulticluster; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_prsmulticluster TO ro_user;
GRANT SELECT ON TABLE public.shdev_prsmulticluster TO devstats_team;


--
-- Name: TABLE shdev_prsnetworking; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_prsnetworking TO ro_user;
GRANT SELECT ON TABLE public.shdev_prsnetworking TO devstats_team;


--
-- Name: TABLE shdev_prsnode; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_prsnode TO ro_user;
GRANT SELECT ON TABLE public.shdev_prsnode TO devstats_team;


--
-- Name: TABLE shdev_prsproject; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_prsproject TO ro_user;
GRANT SELECT ON TABLE public.shdev_prsproject TO devstats_team;


--
-- Name: TABLE shdev_prsprojectinfra; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_prsprojectinfra TO ro_user;
GRANT SELECT ON TABLE public.shdev_prsprojectinfra TO devstats_team;


--
-- Name: TABLE shdev_prssigservicecatalog; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_prssigservicecatalog TO ro_user;
GRANT SELECT ON TABLE public.shdev_prssigservicecatalog TO devstats_team;


--
-- Name: TABLE shdev_prsstorage; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_prsstorage TO ro_user;
GRANT SELECT ON TABLE public.shdev_prsstorage TO devstats_team;


--
-- Name: TABLE shdev_prsui; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_prsui TO ro_user;
GRANT SELECT ON TABLE public.shdev_prsui TO devstats_team;


--
-- Name: TABLE shdev_pushesall; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_pushesall TO ro_user;
GRANT SELECT ON TABLE public.shdev_pushesall TO devstats_team;


--
-- Name: TABLE shdev_pushesapimachinery; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_pushesapimachinery TO ro_user;
GRANT SELECT ON TABLE public.shdev_pushesapimachinery TO devstats_team;


--
-- Name: TABLE shdev_pushesapps; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_pushesapps TO ro_user;
GRANT SELECT ON TABLE public.shdev_pushesapps TO devstats_team;


--
-- Name: TABLE shdev_pushesautoscalingandmonitoring; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_pushesautoscalingandmonitoring TO ro_user;
GRANT SELECT ON TABLE public.shdev_pushesautoscalingandmonitoring TO devstats_team;


--
-- Name: TABLE shdev_pushesclients; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_pushesclients TO ro_user;
GRANT SELECT ON TABLE public.shdev_pushesclients TO devstats_team;


--
-- Name: TABLE shdev_pushesclusterlifecycle; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_pushesclusterlifecycle TO ro_user;
GRANT SELECT ON TABLE public.shdev_pushesclusterlifecycle TO devstats_team;


--
-- Name: TABLE shdev_pushescontrib; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_pushescontrib TO ro_user;
GRANT SELECT ON TABLE public.shdev_pushescontrib TO devstats_team;


--
-- Name: TABLE shdev_pushescsi; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_pushescsi TO ro_user;
GRANT SELECT ON TABLE public.shdev_pushescsi TO devstats_team;


--
-- Name: TABLE shdev_pushesdocs; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_pushesdocs TO ro_user;
GRANT SELECT ON TABLE public.shdev_pushesdocs TO devstats_team;


--
-- Name: TABLE shdev_pusheskubernetes; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_pusheskubernetes TO ro_user;
GRANT SELECT ON TABLE public.shdev_pusheskubernetes TO devstats_team;


--
-- Name: TABLE shdev_pushesmisc; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_pushesmisc TO ro_user;
GRANT SELECT ON TABLE public.shdev_pushesmisc TO devstats_team;


--
-- Name: TABLE shdev_pushesmulticluster; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_pushesmulticluster TO ro_user;
GRANT SELECT ON TABLE public.shdev_pushesmulticluster TO devstats_team;


--
-- Name: TABLE shdev_pushesnetworking; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_pushesnetworking TO ro_user;
GRANT SELECT ON TABLE public.shdev_pushesnetworking TO devstats_team;


--
-- Name: TABLE shdev_pushesnode; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_pushesnode TO ro_user;
GRANT SELECT ON TABLE public.shdev_pushesnode TO devstats_team;


--
-- Name: TABLE shdev_pushesproject; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_pushesproject TO ro_user;
GRANT SELECT ON TABLE public.shdev_pushesproject TO devstats_team;


--
-- Name: TABLE shdev_pushesprojectinfra; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_pushesprojectinfra TO ro_user;
GRANT SELECT ON TABLE public.shdev_pushesprojectinfra TO devstats_team;


--
-- Name: TABLE shdev_pushessigservicecatalog; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_pushessigservicecatalog TO ro_user;
GRANT SELECT ON TABLE public.shdev_pushessigservicecatalog TO devstats_team;


--
-- Name: TABLE shdev_pushesstorage; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_pushesstorage TO ro_user;
GRANT SELECT ON TABLE public.shdev_pushesstorage TO devstats_team;


--
-- Name: TABLE shdev_pushesui; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_pushesui TO ro_user;
GRANT SELECT ON TABLE public.shdev_pushesui TO devstats_team;


--
-- Name: TABLE shdev_review_commentsall; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_review_commentsall TO ro_user;
GRANT SELECT ON TABLE public.shdev_review_commentsall TO devstats_team;


--
-- Name: TABLE shdev_review_commentsapimachinery; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_review_commentsapimachinery TO ro_user;
GRANT SELECT ON TABLE public.shdev_review_commentsapimachinery TO devstats_team;


--
-- Name: TABLE shdev_review_commentsapps; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_review_commentsapps TO ro_user;
GRANT SELECT ON TABLE public.shdev_review_commentsapps TO devstats_team;


--
-- Name: TABLE shdev_review_commentsautoscalingandmonitoring; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_review_commentsautoscalingandmonitoring TO ro_user;
GRANT SELECT ON TABLE public.shdev_review_commentsautoscalingandmonitoring TO devstats_team;


--
-- Name: TABLE shdev_review_commentsclients; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_review_commentsclients TO ro_user;
GRANT SELECT ON TABLE public.shdev_review_commentsclients TO devstats_team;


--
-- Name: TABLE shdev_review_commentsclusterlifecycle; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_review_commentsclusterlifecycle TO ro_user;
GRANT SELECT ON TABLE public.shdev_review_commentsclusterlifecycle TO devstats_team;


--
-- Name: TABLE shdev_review_commentscontrib; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_review_commentscontrib TO ro_user;
GRANT SELECT ON TABLE public.shdev_review_commentscontrib TO devstats_team;


--
-- Name: TABLE shdev_review_commentscsi; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_review_commentscsi TO ro_user;
GRANT SELECT ON TABLE public.shdev_review_commentscsi TO devstats_team;


--
-- Name: TABLE shdev_review_commentsdocs; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_review_commentsdocs TO ro_user;
GRANT SELECT ON TABLE public.shdev_review_commentsdocs TO devstats_team;


--
-- Name: TABLE shdev_review_commentskubernetes; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_review_commentskubernetes TO ro_user;
GRANT SELECT ON TABLE public.shdev_review_commentskubernetes TO devstats_team;


--
-- Name: TABLE shdev_review_commentsmisc; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_review_commentsmisc TO ro_user;
GRANT SELECT ON TABLE public.shdev_review_commentsmisc TO devstats_team;


--
-- Name: TABLE shdev_review_commentsmulticluster; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_review_commentsmulticluster TO ro_user;
GRANT SELECT ON TABLE public.shdev_review_commentsmulticluster TO devstats_team;


--
-- Name: TABLE shdev_review_commentsnetworking; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_review_commentsnetworking TO ro_user;
GRANT SELECT ON TABLE public.shdev_review_commentsnetworking TO devstats_team;


--
-- Name: TABLE shdev_review_commentsnode; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_review_commentsnode TO ro_user;
GRANT SELECT ON TABLE public.shdev_review_commentsnode TO devstats_team;


--
-- Name: TABLE shdev_review_commentsproject; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_review_commentsproject TO ro_user;
GRANT SELECT ON TABLE public.shdev_review_commentsproject TO devstats_team;


--
-- Name: TABLE shdev_review_commentsprojectinfra; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_review_commentsprojectinfra TO ro_user;
GRANT SELECT ON TABLE public.shdev_review_commentsprojectinfra TO devstats_team;


--
-- Name: TABLE shdev_review_commentssigservicecatalog; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_review_commentssigservicecatalog TO ro_user;
GRANT SELECT ON TABLE public.shdev_review_commentssigservicecatalog TO devstats_team;


--
-- Name: TABLE shdev_review_commentsstorage; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_review_commentsstorage TO ro_user;
GRANT SELECT ON TABLE public.shdev_review_commentsstorage TO devstats_team;


--
-- Name: TABLE shdev_review_commentsui; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_review_commentsui TO ro_user;
GRANT SELECT ON TABLE public.shdev_review_commentsui TO devstats_team;


--
-- Name: TABLE shdev_reviewsall; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_reviewsall TO ro_user;
GRANT SELECT ON TABLE public.shdev_reviewsall TO devstats_team;


--
-- Name: TABLE shdev_reviewsapimachinery; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_reviewsapimachinery TO ro_user;
GRANT SELECT ON TABLE public.shdev_reviewsapimachinery TO devstats_team;


--
-- Name: TABLE shdev_reviewsapps; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_reviewsapps TO ro_user;
GRANT SELECT ON TABLE public.shdev_reviewsapps TO devstats_team;


--
-- Name: TABLE shdev_reviewsautoscalingandmonitoring; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_reviewsautoscalingandmonitoring TO ro_user;
GRANT SELECT ON TABLE public.shdev_reviewsautoscalingandmonitoring TO devstats_team;


--
-- Name: TABLE shdev_reviewsclients; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_reviewsclients TO ro_user;
GRANT SELECT ON TABLE public.shdev_reviewsclients TO devstats_team;


--
-- Name: TABLE shdev_reviewsclusterlifecycle; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_reviewsclusterlifecycle TO ro_user;
GRANT SELECT ON TABLE public.shdev_reviewsclusterlifecycle TO devstats_team;


--
-- Name: TABLE shdev_reviewscontrib; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_reviewscontrib TO ro_user;
GRANT SELECT ON TABLE public.shdev_reviewscontrib TO devstats_team;


--
-- Name: TABLE shdev_reviewscsi; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_reviewscsi TO ro_user;
GRANT SELECT ON TABLE public.shdev_reviewscsi TO devstats_team;


--
-- Name: TABLE shdev_reviewsdocs; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_reviewsdocs TO ro_user;
GRANT SELECT ON TABLE public.shdev_reviewsdocs TO devstats_team;


--
-- Name: TABLE shdev_reviewskubernetes; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_reviewskubernetes TO ro_user;
GRANT SELECT ON TABLE public.shdev_reviewskubernetes TO devstats_team;


--
-- Name: TABLE shdev_reviewsmisc; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_reviewsmisc TO ro_user;
GRANT SELECT ON TABLE public.shdev_reviewsmisc TO devstats_team;


--
-- Name: TABLE shdev_reviewsmulticluster; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_reviewsmulticluster TO ro_user;
GRANT SELECT ON TABLE public.shdev_reviewsmulticluster TO devstats_team;


--
-- Name: TABLE shdev_reviewsnetworking; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_reviewsnetworking TO ro_user;
GRANT SELECT ON TABLE public.shdev_reviewsnetworking TO devstats_team;


--
-- Name: TABLE shdev_reviewsnode; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_reviewsnode TO ro_user;
GRANT SELECT ON TABLE public.shdev_reviewsnode TO devstats_team;


--
-- Name: TABLE shdev_reviewsproject; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_reviewsproject TO ro_user;
GRANT SELECT ON TABLE public.shdev_reviewsproject TO devstats_team;


--
-- Name: TABLE shdev_reviewsprojectinfra; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_reviewsprojectinfra TO ro_user;
GRANT SELECT ON TABLE public.shdev_reviewsprojectinfra TO devstats_team;


--
-- Name: TABLE shdev_reviewssigservicecatalog; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_reviewssigservicecatalog TO ro_user;
GRANT SELECT ON TABLE public.shdev_reviewssigservicecatalog TO devstats_team;


--
-- Name: TABLE shdev_reviewsstorage; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_reviewsstorage TO ro_user;
GRANT SELECT ON TABLE public.shdev_reviewsstorage TO devstats_team;


--
-- Name: TABLE shdev_reviewsui; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shdev_reviewsui TO ro_user;
GRANT SELECT ON TABLE public.shdev_reviewsui TO devstats_team;


--
-- Name: TABLE shpr_wlsigs; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.shpr_wlsigs TO ro_user;
GRANT SELECT ON TABLE public.shpr_wlsigs TO devstats_team;


--
-- Name: TABLE siclosed_lsk; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.siclosed_lsk TO ro_user;
GRANT SELECT ON TABLE public.siclosed_lsk TO devstats_team;


--
-- Name: TABLE sissues_age; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.sissues_age TO ro_user;
GRANT SELECT ON TABLE public.sissues_age TO devstats_team;


--
-- Name: TABLE sissues_milestones; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.sissues_milestones TO ro_user;
GRANT SELECT ON TABLE public.sissues_milestones TO devstats_team;


--
-- Name: TABLE snew_contributors; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.snew_contributors TO ro_user;
GRANT SELECT ON TABLE public.snew_contributors TO devstats_team;


--
-- Name: TABLE snew_issues; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.snew_issues TO ro_user;
GRANT SELECT ON TABLE public.snew_issues TO devstats_team;


--
-- Name: TABLE snum_stats; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.snum_stats TO ro_user;
GRANT SELECT ON TABLE public.snum_stats TO devstats_team;


--
-- Name: TABLE spr_apprappr; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spr_apprappr TO ro_user;
GRANT SELECT ON TABLE public.spr_apprappr TO devstats_team;


--
-- Name: TABLE spr_apprwait; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spr_apprwait TO ro_user;
GRANT SELECT ON TABLE public.spr_apprwait TO devstats_team;


--
-- Name: TABLE spr_authall; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spr_authall TO ro_user;
GRANT SELECT ON TABLE public.spr_authall TO devstats_team;


--
-- Name: TABLE spr_authapimachinery; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spr_authapimachinery TO ro_user;
GRANT SELECT ON TABLE public.spr_authapimachinery TO devstats_team;


--
-- Name: TABLE spr_authapps; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spr_authapps TO ro_user;
GRANT SELECT ON TABLE public.spr_authapps TO devstats_team;


--
-- Name: TABLE spr_authautoscalingandmonitoring; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spr_authautoscalingandmonitoring TO ro_user;
GRANT SELECT ON TABLE public.spr_authautoscalingandmonitoring TO devstats_team;


--
-- Name: TABLE spr_authclients; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spr_authclients TO ro_user;
GRANT SELECT ON TABLE public.spr_authclients TO devstats_team;


--
-- Name: TABLE spr_authclusterlifecycle; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spr_authclusterlifecycle TO ro_user;
GRANT SELECT ON TABLE public.spr_authclusterlifecycle TO devstats_team;


--
-- Name: TABLE spr_authcontrib; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spr_authcontrib TO ro_user;
GRANT SELECT ON TABLE public.spr_authcontrib TO devstats_team;


--
-- Name: TABLE spr_authcsi; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spr_authcsi TO ro_user;
GRANT SELECT ON TABLE public.spr_authcsi TO devstats_team;


--
-- Name: TABLE spr_authdocs; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spr_authdocs TO ro_user;
GRANT SELECT ON TABLE public.spr_authdocs TO devstats_team;


--
-- Name: TABLE spr_authkubernetes; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spr_authkubernetes TO ro_user;
GRANT SELECT ON TABLE public.spr_authkubernetes TO devstats_team;


--
-- Name: TABLE spr_authmisc; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spr_authmisc TO ro_user;
GRANT SELECT ON TABLE public.spr_authmisc TO devstats_team;


--
-- Name: TABLE spr_authmulticluster; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spr_authmulticluster TO ro_user;
GRANT SELECT ON TABLE public.spr_authmulticluster TO devstats_team;


--
-- Name: TABLE spr_authnetworking; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spr_authnetworking TO ro_user;
GRANT SELECT ON TABLE public.spr_authnetworking TO devstats_team;


--
-- Name: TABLE spr_authnode; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spr_authnode TO ro_user;
GRANT SELECT ON TABLE public.spr_authnode TO devstats_team;


--
-- Name: TABLE spr_authproject; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spr_authproject TO ro_user;
GRANT SELECT ON TABLE public.spr_authproject TO devstats_team;


--
-- Name: TABLE spr_authprojectinfra; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spr_authprojectinfra TO ro_user;
GRANT SELECT ON TABLE public.spr_authprojectinfra TO devstats_team;


--
-- Name: TABLE spr_authsigservicecatalog; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spr_authsigservicecatalog TO ro_user;
GRANT SELECT ON TABLE public.spr_authsigservicecatalog TO devstats_team;


--
-- Name: TABLE spr_authstorage; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spr_authstorage TO ro_user;
GRANT SELECT ON TABLE public.spr_authstorage TO devstats_team;


--
-- Name: TABLE spr_authui; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spr_authui TO ro_user;
GRANT SELECT ON TABLE public.spr_authui TO devstats_team;


--
-- Name: TABLE spr_comms_med; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spr_comms_med TO ro_user;
GRANT SELECT ON TABLE public.spr_comms_med TO devstats_team;


--
-- Name: TABLE spr_comms_p85; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spr_comms_p85 TO ro_user;
GRANT SELECT ON TABLE public.spr_comms_p85 TO devstats_team;


--
-- Name: TABLE spr_comms_p95; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spr_comms_p95 TO ro_user;
GRANT SELECT ON TABLE public.spr_comms_p95 TO devstats_team;


--
-- Name: TABLE sprblckall; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.sprblckall TO ro_user;
GRANT SELECT ON TABLE public.sprblckall TO devstats_team;


--
-- Name: TABLE sprblckdo_not_merge; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.sprblckdo_not_merge TO ro_user;
GRANT SELECT ON TABLE public.sprblckdo_not_merge TO devstats_team;


--
-- Name: TABLE sprblckneeds_ok_to_test; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.sprblckneeds_ok_to_test TO ro_user;
GRANT SELECT ON TABLE public.sprblckneeds_ok_to_test TO devstats_team;


--
-- Name: TABLE sprblckno_approve; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.sprblckno_approve TO ro_user;
GRANT SELECT ON TABLE public.sprblckno_approve TO devstats_team;


--
-- Name: TABLE sprblckno_lgtm; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.sprblckno_lgtm TO ro_user;
GRANT SELECT ON TABLE public.sprblckno_lgtm TO devstats_team;


--
-- Name: TABLE sprblckrelease_note_label_needed; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.sprblckrelease_note_label_needed TO ro_user;
GRANT SELECT ON TABLE public.sprblckrelease_note_label_needed TO devstats_team;


--
-- Name: TABLE sprs_age; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.sprs_age TO ro_user;
GRANT SELECT ON TABLE public.sprs_age TO devstats_team;


--
-- Name: TABLE sprs_labels; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.sprs_labels TO ro_user;
GRANT SELECT ON TABLE public.sprs_labels TO devstats_team;


--
-- Name: TABLE sprs_milestones; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.sprs_milestones TO ro_user;
GRANT SELECT ON TABLE public.sprs_milestones TO devstats_team;


--
-- Name: TABLE spstatall; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spstatall TO ro_user;
GRANT SELECT ON TABLE public.spstatall TO devstats_team;


--
-- Name: TABLE spstatapimachinery; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spstatapimachinery TO ro_user;
GRANT SELECT ON TABLE public.spstatapimachinery TO devstats_team;


--
-- Name: TABLE spstatapps; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spstatapps TO ro_user;
GRANT SELECT ON TABLE public.spstatapps TO devstats_team;


--
-- Name: TABLE spstatautoscalingandmonitoring; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spstatautoscalingandmonitoring TO ro_user;
GRANT SELECT ON TABLE public.spstatautoscalingandmonitoring TO devstats_team;


--
-- Name: TABLE spstatclients; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spstatclients TO ro_user;
GRANT SELECT ON TABLE public.spstatclients TO devstats_team;


--
-- Name: TABLE spstatclusterlifecycle; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spstatclusterlifecycle TO ro_user;
GRANT SELECT ON TABLE public.spstatclusterlifecycle TO devstats_team;


--
-- Name: TABLE spstatcontrib; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spstatcontrib TO ro_user;
GRANT SELECT ON TABLE public.spstatcontrib TO devstats_team;


--
-- Name: TABLE spstatcsi; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spstatcsi TO ro_user;
GRANT SELECT ON TABLE public.spstatcsi TO devstats_team;


--
-- Name: TABLE spstatdocs; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spstatdocs TO ro_user;
GRANT SELECT ON TABLE public.spstatdocs TO devstats_team;


--
-- Name: TABLE spstatkubernetes; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spstatkubernetes TO ro_user;
GRANT SELECT ON TABLE public.spstatkubernetes TO devstats_team;


--
-- Name: TABLE spstatmisc; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spstatmisc TO ro_user;
GRANT SELECT ON TABLE public.spstatmisc TO devstats_team;


--
-- Name: TABLE spstatmulticluster; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spstatmulticluster TO ro_user;
GRANT SELECT ON TABLE public.spstatmulticluster TO devstats_team;


--
-- Name: TABLE spstatnetworking; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spstatnetworking TO ro_user;
GRANT SELECT ON TABLE public.spstatnetworking TO devstats_team;


--
-- Name: TABLE spstatnode; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spstatnode TO ro_user;
GRANT SELECT ON TABLE public.spstatnode TO devstats_team;


--
-- Name: TABLE spstatproject; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spstatproject TO ro_user;
GRANT SELECT ON TABLE public.spstatproject TO devstats_team;


--
-- Name: TABLE spstatprojectinfra; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spstatprojectinfra TO ro_user;
GRANT SELECT ON TABLE public.spstatprojectinfra TO devstats_team;


--
-- Name: TABLE spstatsigservicecatalog; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spstatsigservicecatalog TO ro_user;
GRANT SELECT ON TABLE public.spstatsigservicecatalog TO devstats_team;


--
-- Name: TABLE spstatstorage; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spstatstorage TO ro_user;
GRANT SELECT ON TABLE public.spstatstorage TO devstats_team;


--
-- Name: TABLE spstatui; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.spstatui TO ro_user;
GRANT SELECT ON TABLE public.spstatui TO devstats_team;


--
-- Name: TABLE ssig_pr_wlabs; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.ssig_pr_wlabs TO ro_user;
GRANT SELECT ON TABLE public.ssig_pr_wlabs TO devstats_team;


--
-- Name: TABLE ssig_pr_wliss; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.ssig_pr_wliss TO ro_user;
GRANT SELECT ON TABLE public.ssig_pr_wliss TO devstats_team;


--
-- Name: TABLE ssig_pr_wlrel; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.ssig_pr_wlrel TO ro_user;
GRANT SELECT ON TABLE public.ssig_pr_wlrel TO devstats_team;


--
-- Name: TABLE ssig_pr_wlrev; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.ssig_pr_wlrev TO ro_user;
GRANT SELECT ON TABLE public.ssig_pr_wlrev TO devstats_team;


--
-- Name: TABLE ssigm_lsk; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.ssigm_lsk TO ro_user;
GRANT SELECT ON TABLE public.ssigm_lsk TO devstats_team;


--
-- Name: TABLE ssigm_txt; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.ssigm_txt TO ro_user;
GRANT SELECT ON TABLE public.ssigm_txt TO devstats_team;


--
-- Name: TABLE stime_metrics; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.stime_metrics TO ro_user;
GRANT SELECT ON TABLE public.stime_metrics TO devstats_team;


--
-- Name: TABLE suser_reviews; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.suser_reviews TO ro_user;
GRANT SELECT ON TABLE public.suser_reviews TO devstats_team;


--
-- Name: TABLE swatchers; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.swatchers TO ro_user;
GRANT SELECT ON TABLE public.swatchers TO devstats_team;


--
-- Name: TABLE tall_combined_repo_groups; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.tall_combined_repo_groups TO ro_user;
GRANT SELECT ON TABLE public.tall_combined_repo_groups TO devstats_team;


--
-- Name: TABLE tall_milestones; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.tall_milestones TO ro_user;
GRANT SELECT ON TABLE public.tall_milestones TO devstats_team;


--
-- Name: TABLE tall_repo_groups; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.tall_repo_groups TO ro_user;
GRANT SELECT ON TABLE public.tall_repo_groups TO devstats_team;


--
-- Name: TABLE tall_repo_names; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.tall_repo_names TO ro_user;
GRANT SELECT ON TABLE public.tall_repo_names TO devstats_team;


--
-- Name: TABLE tbot_commands; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.tbot_commands TO ro_user;
GRANT SELECT ON TABLE public.tbot_commands TO devstats_team;


--
-- Name: TABLE tcompanies; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.tcompanies TO ro_user;
GRANT SELECT ON TABLE public.tcompanies TO devstats_team;


--
-- Name: TABLE tpr_labels_tags; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.tpr_labels_tags TO ro_user;
GRANT SELECT ON TABLE public.tpr_labels_tags TO devstats_team;


--
-- Name: TABLE tpriority_labels_with_all; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.tpriority_labels_with_all TO ro_user;
GRANT SELECT ON TABLE public.tpriority_labels_with_all TO devstats_team;


--
-- Name: TABLE tquick_ranges; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.tquick_ranges TO ro_user;
GRANT SELECT ON TABLE public.tquick_ranges TO devstats_team;


--
-- Name: TABLE trepo_groups; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.trepo_groups TO ro_user;
GRANT SELECT ON TABLE public.trepo_groups TO devstats_team;


--
-- Name: TABLE treviewers; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.treviewers TO ro_user;
GRANT SELECT ON TABLE public.treviewers TO devstats_team;


--
-- Name: TABLE tsig_mentions_labels; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.tsig_mentions_labels TO ro_user;
GRANT SELECT ON TABLE public.tsig_mentions_labels TO devstats_team;


--
-- Name: TABLE tsig_mentions_labels_with_all; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.tsig_mentions_labels_with_all TO ro_user;
GRANT SELECT ON TABLE public.tsig_mentions_labels_with_all TO devstats_team;


--
-- Name: TABLE tsig_mentions_texts; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.tsig_mentions_texts TO ro_user;
GRANT SELECT ON TABLE public.tsig_mentions_texts TO devstats_team;


--
-- Name: TABLE tsigm_lbl_kinds; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.tsigm_lbl_kinds TO ro_user;
GRANT SELECT ON TABLE public.tsigm_lbl_kinds TO devstats_team;


--
-- Name: TABLE tsigm_lbl_kinds_with_all; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.tsigm_lbl_kinds_with_all TO ro_user;
GRANT SELECT ON TABLE public.tsigm_lbl_kinds_with_all TO devstats_team;


--
-- Name: TABLE tsize_labels_with_all; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.tsize_labels_with_all TO ro_user;
GRANT SELECT ON TABLE public.tsize_labels_with_all TO devstats_team;


--
-- Name: TABLE ttop_repo_names; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.ttop_repo_names TO ro_user;
GRANT SELECT ON TABLE public.ttop_repo_names TO devstats_team;


--
-- Name: TABLE ttop_repo_names_with_all; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.ttop_repo_names_with_all TO ro_user;
GRANT SELECT ON TABLE public.ttop_repo_names_with_all TO devstats_team;


--
-- Name: TABLE ttop_repos_with_all; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.ttop_repos_with_all TO ro_user;
GRANT SELECT ON TABLE public.ttop_repos_with_all TO devstats_team;


--
-- Name: TABLE tusers; Type: ACL; Schema: public; Owner: gha_admin
--

GRANT SELECT ON TABLE public.tusers TO ro_user;
GRANT SELECT ON TABLE public.tusers TO devstats_team;


--
-- PostgreSQL database dump complete
--

