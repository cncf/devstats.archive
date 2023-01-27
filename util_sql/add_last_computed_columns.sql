alter table gha_last_computed add start_dt timestamp without time zone;
alter table gha_last_computed add took interval;
alter table gha_last_computed add took_as_str character varying(64);
alter table gha_last_computed add command character varying(512);
