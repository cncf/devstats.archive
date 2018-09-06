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
-- PostgreSQL database dump complete
--

