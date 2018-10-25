select
  distinct sha,
  dup_actor_login,
  dup_author_login,
  dup_committer_login
from
  gha_commits
where
  dup_actor_login != dup_author_login
  and dup_actor_login != dup_committer_login
  and dup_author_login != dup_committer_login
  and dup_author_login != ''
  and dup_committer_login != ''
  and dup_actor_login != ''
;
