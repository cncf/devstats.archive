CREATE TABLE public.gha_last_computed (
    metric text NOT NULL,
    dt timestamp without time zone NOT NULL
);
ALTER TABLE public.gha_last_computed OWNER TO gha_admin;
ALTER TABLE ONLY public.gha_last_computed
    ADD CONSTRAINT gha_last_computed_pkey PRIMARY KEY (metric);
