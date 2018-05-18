CREATE TABLE gha_parsed (
    dt timestamp without time zone NOT NULL
);
ALTER TABLE gha_parsed OWNER TO gha_admin;
ALTER TABLE ONLY gha_parsed ADD CONSTRAINT gha_parsed_pkey PRIMARY KEY (dt);
insert into gha_parsed(dt) select date_trunc('hour', max(created_at)) from gha_events;
