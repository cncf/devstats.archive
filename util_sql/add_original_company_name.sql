alter table gha_actors_affiliations add original_company_name varchar(160);
update gha_actors_affiliations set original_company_name = company_name;
alter table gha_actors_affiliations alter column original_company_name set not null;
create index actors_affiliations_original_company_name_idx on gha_actors_affiliations(original_company_name);
