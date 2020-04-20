select
  *
from (
  values
    ('pr-review'),
    ('misc'),
    ('bug'),
    ('api-review'),
    ('feature-request'),
    ('proposal'),
    ('test-failure'),
    ('design-proposal'),
    ('owners'),
  ) as temp(cat)
;
