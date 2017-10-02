create temp table issues as
select distinct id,
  user_id,
  created_at
from
  gha_issues
where
  created_at >= '{{from}}'
  and created_at <= '{{to}}';

select
  i.id,
  i.user_id,
  gi.dup_actor_id,
  to_char(i.created_at, 'YYYY-MM-DD HH24:MI:SS'),
  to_char(gi.updated_at, 'YYYY-MM-DD HH24:MI:SS'),
  gi.updated_at - i.created_at
from
  issues i,
  gha_issues gi
where
  i.id = gi.id
  and gi.dup_actor_login not in ('googlebot')
  and gi.dup_actor_login not like 'k8s-%'
  and gi.dup_actor_login not like '%-bot'
  and gi.event_id = (select event_id from gha_issues evs where evs.dup_actor_id != i.user_id and evs.id = i.id order by evs.updated_at asc limit 1)
;

drop table issues;
