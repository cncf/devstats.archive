update gha_events e set type = (select p.dup_type from gha_payloads p where p.event_id = e.id) where e.type like 'Art%';
update gha_issues i set dup_type = (select p.dup_type from gha_payloads p where p.event_id = i.event_id) where i.dup_type like 'Art%';
