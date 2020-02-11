select
  distinct license_name
from
  gha_repos
where
  license_name is not null
  and license_name not in ('', 'Not found')
;
