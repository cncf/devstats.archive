CREATE TABLE gha_computed (
    metric text NOT NULL,
    dt timestamp without time zone NOT NULL
);
ALTER TABLE gha_computed OWNER TO gha_admin;
