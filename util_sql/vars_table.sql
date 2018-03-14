CREATE TABLE gha_vars (
  name character varying(100) NOT NULL,
  value_i bigint,
  value_f double precision,
  value_s text,
  value_dt timestamp without time zone
);
ALTER TABLE gha_vars OWNER TO gha_admin;
ALTER TABLE ONLY gha_vars ADD CONSTRAINT gha_vars_pkey PRIMARY KEY (name);
CREATE INDEX vars_name_idx ON gha_vars USING btree (name);
