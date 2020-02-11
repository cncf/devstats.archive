select
  distinct lang_name
from
  gha_repos_langs
where
  lang_name is not null
  and lang_name not in ('', 'unknown')
;
