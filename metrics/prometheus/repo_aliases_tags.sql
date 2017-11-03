select
  distinct alias
from
  gha_repos
where
  alias is not null
order by
  alias asc
;
