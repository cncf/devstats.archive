CREATE TABLE public.gha_last_computed (
    metric text NOT NULL,
    dt timestamp without time zone NOT NULL
);
ALTER TABLE public.gha_last_computed OWNER TO gha_admin;
ALTER TABLE ONLY public.gha_last_computed
    ADD CONSTRAINT gha_last_computed_pkey PRIMARY KEY (metric);
grant select on gha_last_computed to "devstats_team";
grant select on gha_last_computed to "ro_user";
