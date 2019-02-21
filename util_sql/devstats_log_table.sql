CREATE TABLE gha_logs (
    id integer NOT NULL,
    dt timestamp without time zone DEFAULT now(),
    prog character varying(32) not null default '',
    proj character varying(32) not null,
    run_dt timestamp without time zone not null,
    msg text
);
ALTER TABLE gha_logs OWNER TO gha_admin;
CREATE SEQUENCE gha_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER TABLE gha_logs_id_seq OWNER TO gha_admin;
