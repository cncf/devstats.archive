select 1001 as ord, (select timestamp from start_date) as f, '2016-02-12T23:00:00' as t, 'start - v0.0.5' as rel
union select 1002 as ord, '2016-02-12T23:00:00'::timestamp as f, '2016-03-21T20:00:00'::timestamp as t, 'v0.0.5 - v0.1.0' as rel
union select 1003 as ord, '2016-03-21T20:00:00'::timestamp as f, '2016-04-14T21:00:00'::timestamp as t, 'v0.1.0 - v0.2.0' as rel
union select 1004 as ord, '2016-04-14T21:00:00'::timestamp as f, '2017-05-30T16:00:00'::timestamp as t, 'v0.2.0 - v0.2.9' as rel
union select 1005 as ord, '2017-05-30T16:00:00'::timestamp as f, '2017-07-13T00:00:00'::timestamp as t, 'v0.2.9 - v1.0.0-alpha0' as rel
union select 1006 as ord, '2017-07-13T00:00:00'::timestamp as f, '2017-08-23T22:00:00'::timestamp as t, 'v1.0.0-alpha0 - v1.0.0-alpha6' as rel
union select 1007 as ord, '2017-08-23T22:00:00'::timestamp as f, '2017-09-06T23:00:00'::timestamp as t, 'v1.0.0-alpha6 - v1.0.0-beta.0' as rel
union select 1008 as ord, '2017-09-06T23:00:00'::timestamp as f, '2017-11-08T19:00:00'::timestamp as t, 'v1.0.0-beta.0 - v1.0.0-beta.3' as rel
union select 1009 as ord, '2017-11-08T19:00:00'::timestamp as f, '2017-12-05T05:00:00'::timestamp as t, 'v1.0.0-beta.3 - v1.0.0' as rel
union select 1010 as ord, '2017-12-05T05:00:00'::timestamp as f, '2018-01-17T19:00:00'::timestamp as t, 'v1.0.0 - v1.0.1' as rel
union select 1011 as ord, '2018-01-17T19:00:00'::timestamp as f, '2018-02-13T23:00:00'::timestamp as t, 'v1.0.1 - v1.0.2' as rel
union select 1012 as ord, '2018-02-13T23:00:00'::timestamp as f, '2018-04-02T20:00:00'::timestamp as t, 'v1.0.2 - v1.0.3' as rel
union select 1013 as ord, '2018-04-02T20:00:00'::timestamp as f, '2018-04-05T00:00:00'::timestamp as t, 'v1.0.3 - v1.1.0-rc.1' as rel
union select 1014 as ord, '2018-04-05T00:00:00Z'::timestamp as f, now()::date as t, 'v1.1.0.rc.1 - now' as rel
