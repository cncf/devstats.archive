select 1001 as ord, (select timestamp from start_date) as f, '2015-01-26 14:54:01' as t, 'start - v0.10.0' as rel
union select 1002 as ord, '2015-01-26 14:54:01'::timestamp as f, '2016-06-15 15:52:52'::timestamp as t, 'v0.10.0 - v0.20.0' as rel
union select 1003 as ord, '2016-06-15 15:52:52'::timestamp as f, '2016-07-18 14:19:29'::timestamp as t, 'v0.20.0 - v1.0.0' as rel
union select 1004 as ord, '2016-07-18 14:19:29'::timestamp as f, '2016-09-03 19:01:04'::timestamp as t, 'v1.0.0 - v1.1.0' as rel
union select 1005 as ord, '2016-09-03 19:01:04'::timestamp as f, '2016-10-07 12:50:26'::timestamp as t, 'v1.1.0 - v1.2.0' as rel
union select 1006 as ord, '2016-10-07 12:50:26'::timestamp as f, '2016-11-01 16:24:33'::timestamp as t, 'v1.2.0 - v1.3.0' as rel
union select 1007 as ord, '2016-11-01 16:24:33'::timestamp as f, '2016-11-25 12:35:04'::timestamp as t, 'v1.3.0 - v1.4.0' as rel
union select 1008 as ord, '2016-11-25 12:35:04'::timestamp as f, '2017-01-23 13:09:57'::timestamp as t, 'v1.4.0 - v1.5.0' as rel
union select 1009 as ord, '2017-01-23 13:09:57'::timestamp as f, '2017-04-14 18:14:27'::timestamp as t, 'v1.5.0 - v1.6.0' as rel
union select 1010 as ord, '2017-04-14 18:14:27'::timestamp as f, '2017-06-07 09:41:34'::timestamp as t, 'v1.6.0 - v1.7.0' as rel
union select 1011 as ord, '2017-06-07 09:41:34'::timestamp as f, '2017-10-06 22:10:48'::timestamp as t, 'v1.7.0 - v1.8.0' as rel
union select 1012 as ord, '2017-10-06 22:10:48'::timestamp as f, '2017-11-08 07:09:51'::timestamp as t, 'v1.8.0 - v2.0.0' as rel
union select 1013 as ord, '2017-11-08 07:09:51'::timestamp as f, '2018-01-19 11:57:45'::timestamp as t, 'v2.0.0 - v2.1.0' as rel
union select 1014 as ord, '2018-01-19 11:57:45'::timestamp as f, '2018-03-08 16:37:57'::timestamp as t, 'v2.1.0 - v2.2.0' as rel
union select 1015 as ord, '2018-03-08 16:37:57'::timestamp as f, now()::date as t, 'v2.2.0 - now' as rel
