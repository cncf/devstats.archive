update org set name = '{{org}}' where id = 1;
insert into star(id, user_id, dashboard_id) select 1, 1, id from dashboard where uid = {{uid}};
insert into preferences(id, org_id, user_id, version, home_dashboard_id, timezone, theme, created, updated) select 1, 1, 1, 0, (select id from dashboard where uid = {{uid}}), '', 'dark', datetime('now'), datetime('now');
insert into preferences(id, org_id, user_id, version, home_dashboard_id, timezone, theme, created, updated) select 2, 1, 0, 0, (select id from dashboard where uid = {{uid}}), '', 'dark', datetime('now'), datetime('now');
