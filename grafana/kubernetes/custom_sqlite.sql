delete from dashboard_tag where dashboard_id = (select id from dashboard where uid = {{uid}});
insert into dashboard_tag(dashboard_id, term) values((select id from dashboard where uid = {{uid}}), 'home');
insert into dashboard_tag(dashboard_id, term) values((select id from dashboard where uid = {{uid}}), 'all');
insert into dashboard_tag(dashboard_id, term) values((select id from dashboard where uid = {{uid}}), 'kubernetes');
