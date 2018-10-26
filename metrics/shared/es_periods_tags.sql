select
  'h' as devstats_period,
  '1h' as es_period_name
union select 'h24', '1h'
union select 'd', '1d'
union select 'd7', '1d'
union select 'd10', '1d'
union select 'd28', '1d'
union select 'w', '1w'
union select 'm', '1m'
union select 'q', '1q'
union select 'y', '1y'
union select 'y10', '1y'
;
