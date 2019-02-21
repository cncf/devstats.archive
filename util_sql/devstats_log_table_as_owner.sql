ALTER SEQUENCE gha_logs_id_seq OWNED BY gha_logs.id;
ALTER TABLE ONLY gha_logs ALTER COLUMN id SET DEFAULT nextval('gha_logs_id_seq'::regclass);
CREATE INDEX logs_dt_idx ON gha_logs USING btree (dt);
CREATE INDEX logs_id_idx ON gha_logs USING btree (id);
CREATE INDEX logs_prog_idx ON gha_logs USING btree (prog);
CREATE INDEX logs_proj_idx ON gha_logs USING btree (proj);
CREATE INDEX logs_run_dt_idx ON gha_logs USING btree (run_dt);
