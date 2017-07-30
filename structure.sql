--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.3
-- Dumped by pg_dump version 9.6.3

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
    login character varying(80) NOT NULL
);


ALTER TABLE gha_actors OWNER TO gha_admin;

--
-- Name: gha_commits; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_commits (
    sha character varying(40) NOT NULL,
    author_name character varying(160) NOT NULL,
    author_email character varying(160) NOT NULL,
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
    payload_id bigint NOT NULL,
    public boolean NOT NULL,
    created_at timestamp without time zone NOT NULL,
    org_id bigint
);


ALTER TABLE gha_events OWNER TO gha_admin;

--
-- Name: gha_orgs; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_orgs (
    id bigint NOT NULL,
    login character varying(80) NOT NULL
);


ALTER TABLE gha_orgs OWNER TO gha_admin;

--
-- Name: gha_pages; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_pages (
    sha character varying(40) NOT NULL,
    action character varying(20) NOT NULL,
    page_name character varying(160) NOT NULL,
    title character varying(160) NOT NULL
);


ALTER TABLE gha_pages OWNER TO gha_admin;

--
-- Name: gha_payloads; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_payloads (
    id bigint NOT NULL,
    push_id integer,
    size integer,
    ref character varying(160),
    head character varying(40),
    before character varying(40),
    action character varying(20),
    issue_id bigint,
    comment_id bigint,
    ref_type character varying(20),
    master_branch character varying(160),
    description text,
    number integer,
    forkee_id bigint,
    release_id bigint,
    member_id bigint
);


ALTER TABLE gha_payloads OWNER TO gha_admin;

--
-- Name: gha_payloads_commits; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_payloads_commits (
    payload_id bigint NOT NULL,
    sha character varying(40) NOT NULL
);


ALTER TABLE gha_payloads_commits OWNER TO gha_admin;

--
-- Name: gha_payloads_pages; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_payloads_pages (
    payload_id bigint NOT NULL,
    sha character varying(40) NOT NULL
);


ALTER TABLE gha_payloads_pages OWNER TO gha_admin;

--
-- Name: gha_repos; Type: TABLE; Schema: public; Owner: gha_admin
--

CREATE TABLE gha_repos (
    id bigint NOT NULL,
    name character varying(160) NOT NULL
);


ALTER TABLE gha_repos OWNER TO gha_admin;

--
-- Data for Name: gha_actors; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_actors (id, login) FROM stdin;
\.


--
-- Data for Name: gha_commits; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_commits (sha, author_name, author_email, message, is_distinct) FROM stdin;
\.


--
-- Data for Name: gha_events; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_events (id, type, actor_id, repo_id, payload_id, public, created_at, org_id) FROM stdin;
\.


--
-- Data for Name: gha_orgs; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_orgs (id, login) FROM stdin;
\.


--
-- Data for Name: gha_pages; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_pages (sha, action, page_name, title) FROM stdin;
\.


--
-- Data for Name: gha_payloads; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_payloads (id, push_id, size, ref, head, before, action, issue_id, comment_id, ref_type, master_branch, description, number, forkee_id, release_id, member_id) FROM stdin;
\.


--
-- Data for Name: gha_payloads_commits; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_payloads_commits (payload_id, sha) FROM stdin;
\.


--
-- Data for Name: gha_payloads_pages; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_payloads_pages (payload_id, sha) FROM stdin;
\.


--
-- Data for Name: gha_repos; Type: TABLE DATA; Schema: public; Owner: gha_admin
--

COPY gha_repos (id, name) FROM stdin;
\.


--
-- Name: gha_actors gha_actors_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_actors
    ADD CONSTRAINT gha_actors_pkey PRIMARY KEY (id);


--
-- Name: gha_commits gha_commits_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_commits
    ADD CONSTRAINT gha_commits_pkey PRIMARY KEY (sha);


--
-- Name: gha_events gha_events_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_events
    ADD CONSTRAINT gha_events_pkey PRIMARY KEY (id);


--
-- Name: gha_orgs gha_orgs_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_orgs
    ADD CONSTRAINT gha_orgs_pkey PRIMARY KEY (id);


--
-- Name: gha_pages gha_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_pages
    ADD CONSTRAINT gha_pages_pkey PRIMARY KEY (sha);


--
-- Name: gha_payloads_commits gha_payloads_commits_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_payloads_commits
    ADD CONSTRAINT gha_payloads_commits_pkey PRIMARY KEY (payload_id, sha);


--
-- Name: gha_payloads_pages gha_payloads_pages_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_payloads_pages
    ADD CONSTRAINT gha_payloads_pages_pkey PRIMARY KEY (payload_id, sha);


--
-- Name: gha_payloads gha_payloads_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_payloads
    ADD CONSTRAINT gha_payloads_pkey PRIMARY KEY (id);


--
-- Name: gha_repos gha_repos_pkey; Type: CONSTRAINT; Schema: public; Owner: gha_admin
--

ALTER TABLE ONLY gha_repos
    ADD CONSTRAINT gha_repos_pkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--

