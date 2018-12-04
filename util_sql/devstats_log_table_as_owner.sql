ALTER SEQUENCE gha_logs_id_seq OWNED BY gha_logs.id;
ALTER TABLE ONLY gha_logs ALTER COLUMN id SET DEFAULT nextval('gha_logs_id_seq'::regclass);
CREATE INDEX logs_dt_idx ON gha_logs USING btree (dt);
CREATE INDEX logs_id_idx ON gha_logs USING btree (id);
