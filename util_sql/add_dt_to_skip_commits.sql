alter table gha_skip_commits add dt timestamp without time zone;
update gha_skip_commits set dt = now();
alter table gha_skip_commits alter column dt set not null;
