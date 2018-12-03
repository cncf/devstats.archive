REVOKE ALL ON ALL TABLES IN SCHEMA public FROM "{{user}}";
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM "{{user}}";
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM "{{user}}";
REASSIGN OWNED BY "{{user}}" TO {{admin_user}};
DROP OWNED BY "{{user}}";
DROP USER "{{user}}";
