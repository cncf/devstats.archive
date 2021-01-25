select
  *
from (
  values
    ('countries/Week/w'),
    ('countries/Month/m'),
    ('countries/Quarter/q'),
    ('countries/Year/y'),
    ('countries/2 Years MA/y2'),
    ('countries/3 Years MA/y3'),
    ('countries/5 Years MA/y5'),
    ('countriescum/Month/m')
  ) as temp(cat)
;
