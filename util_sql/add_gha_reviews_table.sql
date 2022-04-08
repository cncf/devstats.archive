CREATE TABLE public.gha_reviews (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    commit_id character varying(40) NOT NULL,
    submitted_at timestamp without time zone NOT NULL,
    author_association text NOT NULL,
    state text NOT NULL,
    body text,
    event_id bigint NOT NULL,
    dup_actor_id bigint NOT NULL,
    dup_actor_login character varying(120) NOT NULL,
    dup_repo_id bigint NOT NULL,
    dup_repo_name character varying(160) NOT NULL,
    dup_type character varying(40) NOT NULL,
    dup_created_at timestamp without time zone NOT NULL,
    dup_user_login character varying(120) NOT NULL
);
ALTER TABLE public.gha_reviews OWNER TO gha_admin;
COPY public.gha_reviews (id, user_id, commit_id, submitted_at, author_association, state, body, event_id, dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, dup_user_login) FROM stdin;
\.
ALTER TABLE ONLY public.gha_reviews
    ADD CONSTRAINT gha_reviews_pkey PRIMARY KEY (id, event_id);
CREATE INDEX reviews_commit_id_idx ON public.gha_reviews USING btree (commit_id);
CREATE INDEX reviews_dup_actor_id_idx ON public.gha_reviews USING btree (dup_actor_id);
CREATE INDEX reviews_dup_actor_login_idx ON public.gha_reviews USING btree (dup_actor_login);
CREATE INDEX reviews_dup_repo_id_idx ON public.gha_reviews USING btree (dup_repo_id);
CREATE INDEX reviews_dup_repo_name_idx ON public.gha_reviews USING btree (dup_repo_name);
CREATE INDEX reviews_dup_type_idx ON public.gha_reviews USING btree (dup_type);
CREATE INDEX reviews_dup_user_login_idx ON public.gha_reviews USING btree (dup_user_login);
CREATE INDEX reviews_event_id_idx ON public.gha_reviews USING btree (event_id);
CREATE INDEX reviews_submitted_at_idx ON public.gha_reviews USING btree (submitted_at);
CREATE INDEX reviews_user_id_idx ON public.gha_reviews USING btree (user_id);
