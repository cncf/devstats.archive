update gha_commits c set dup_author_login = (select a.login from gha_actors a where a.id = c.author_id) where c.dup_author_login = '' and c.author_id is not null;
update gha_commits c set dup_committer_login = (select a.login from gha_actors a where a.id = c.committer_id) where c.dup_committer_login = '' and c.committer_id is not null;
