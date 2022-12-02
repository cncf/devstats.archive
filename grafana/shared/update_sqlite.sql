DELETE FROM builtin_role where role_id IN (SELECT id FROM role WHERE name LIKE 'managed:%');
DELETE FROM team_role where role_id IN (SELECT id FROM role WHERE name LIKE 'managed:%');
DELETE FROM user_role where role_id IN (SELECT id FROM role WHERE name LIKE 'managed:%');
DELETE FROM permission where role_id IN (SELECT id FROM role WHERE name LIKE 'managed:%');
DELETE FROM role WHERE name LIKE 'managed:%';
DELETE FROM migration_log WHERE migration_id IN (
  'teams permissions migration',
  'dashboard permissions',
  'dashboard permissions uid scopes',
  'data source permissions',
  'data source uid permissions',
  'managed permissions migration',
  'managed folder permissions alert actions repeated migration',
  'managed permissions migration enterprise'
);

select * from org;
update org set name = '{{org}}' where id = 1;
select * from org;
select * from star;
insert into star(id, user_id, dashboard_id) select 1, 1, id from dashboard where slug = 'dashboards';
select * from star;
select * from preferences;
insert into preferences(id, org_id, user_id, version, home_dashboard_id, timezone, theme, created, updated) select 1, 1, 1, 0, (select id from dashboard where slug = 'dashboards'), '', 'dark', datetime('now'), datetime('now');
insert into preferences(id, org_id, user_id, version, home_dashboard_id, timezone, theme, created, updated) select 2, 1, 0, 0, (select id from dashboard where slug = 'dashboards'), '', 'dark', datetime('now'), datetime('now');
select * from preferences;
select * from user;
select id, uid, slug, title from dashboard;
