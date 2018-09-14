select
  *
from (
  values
    ('sex/Week/w'),
    ('sex/Month/m'),
    ('sex/Quarter/q'),
    ('sex/Year/y'),
    ('sexcum/Month/m'),
    ('countries/Week/w'),
    ('countries/Month/m'),
    ('countries/Quarter/q'),
    ('countries/Year/y'),
    ('countriescum/Month/m')
  ) as temp(cat)
;
