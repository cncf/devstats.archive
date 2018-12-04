drop database lfn;
drop database devstats;
revoke all privileges on schema public from gha_admin;
revoke all privileges on schema public from ro_user;
revoke all privileges on schema public from devstats_team;
drop role gha_admin;
drop role ro_user;  
drop role devstats_team;
