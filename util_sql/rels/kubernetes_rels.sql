select 1001 as ord, (select timestamp from start_date) as f, '2015-07-11 04:02:31' as t, 'start - v1.0.0' as rel
union select 1002 as ord, '2015-07-11 04:02:31'::timestamp as f, '2015-09-25 23:41:40'::timestamp as t, 'v1.0.0 - v1.1.0' as rel
union select 1003 as ord, '2015-09-25 23:41:40'::timestamp as f, '2016-03-16 22:01:03'::timestamp as t, 'v1.1.0 - v1.2.0' as rel
union select 1004 as ord, '2016-03-16 22:01:03'::timestamp as f, '2016-07-01 19:19:06'::timestamp as t, 'v1.2.0 - v1.3.0' as rel
union select 1005 as ord, '2016-07-01 19:19:06'::timestamp as f, '2016-09-26 18:09:47'::timestamp as t, 'v1.3.0 - v1.4.0' as rel
union select 1006 as ord, '2016-09-26 18:09:47'::timestamp as f, '2016-12-12 23:29:43'::timestamp as t, 'v1.4.0 - v1.5.0' as rel
union select 1007 as ord, '2016-12-12 23:29:43'::timestamp as f, '2017-03-28 16:23:06'::timestamp as t, 'v1.5.0 - v1.6.0' as rel
union select 1008 as ord, '2017-03-28 16:23:06'::timestamp as f, '2017-06-29 22:53:16'::timestamp as t, 'v1.6.0 - v1.7.0' as rel
union select 1009 as ord, '2017-06-29 22:53:16'::timestamp as f, '2017-09-28 22:13:57'::timestamp as t, 'v1.7.0 - v1.8.0' as rel
union select 1010 as ord, '2017-09-28 22:13:57'::timestamp as f, '2017-12-15 20:53:13'::timestamp as t, 'v1.8.0 - v1.9.0' as rel
union select 1011 as ord, '2017-12-15 20:53:13'::timestamp as f, '2018-03-26 16:41:58'::timestamp as t, 'v1.9.0 - v1.10.0' as rel
union select 1012 as ord, '2018-03-26 16:41:58'::timestamp as f, now()::date as t, 'v1.10.0 - now' as rel
