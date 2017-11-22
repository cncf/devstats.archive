create table session(
  key char(16) not null,
  data bytea,
  expiry integer not null,
  primary key(key)
);
grant all privileges on table "session" to gha_admin;
