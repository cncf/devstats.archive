create table {{table}}_temp (like {{table}});
insert into {{table}}_temp select distinct * from {{table}};
drop table {{table}};
alter table {{table}}_temp rename to {{table}};
alter table {{table}} owner to gha_admin;
