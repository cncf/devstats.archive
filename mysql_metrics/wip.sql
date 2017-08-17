select
  distinct preg_capture('{(@kubernetes/sig-[\\w-]+)(-bugs|-feature-request|-pr-review|-api-review|-misc|-proposal|-design-proposal|-test-failure)s?\\s+}i', body)
from
  gha_comments
where
  preg_capture('{(@kubernetes/sig-[\\w-]+)(-bugs|-feature-request|-pr-review|-api-review|-misc|-proposal|-design-proposal|-test-failure)s?\\s+}i', body) is not null
