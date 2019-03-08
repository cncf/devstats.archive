update org set name = 'Kubernetes' where id = 1;
insert into star(id, user_id, dashboard_id) select 1, 1, id from dashboard where uid = 12;
insert into preferences select 1,1,1,0,(select id from dashboard where uid = 12),'','dark',datetime('now'),datetime('now'),0;
insert into preferences select 2,1,0,0,(select id from dashboard where uid = 12),'','dark',datetime('now'),datetime('now'),0;
