CREATE TABLE gha_computed (
    metric text NOT NULL,
    dt timestamp without time zone NOT NULL
);
ALTER TABLE gha_computed OWNER TO gha_admin;
ALTER TABLE ONLY gha_computed ADD CONSTRAINT gha_computed_pkey PRIMARY KEY (metric, dt);
CREATE INDEX computed_dt_idx ON gha_computed USING btree (dt);
CREATE INDEX computed_metric_idx ON gha_computed USING btree (metric);
