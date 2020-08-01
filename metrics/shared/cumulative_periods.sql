select
  *
from (
  values
    ('countries/Week/w'),
    ('countries/Month/m'),
    ('countries/Quarter/q'),
    ('countries/Year/y'),
    ('countriescum/Month/m')
  ) as temp(cat)
;
