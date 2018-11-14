select period, max(time) as dt, min(time) as mindt from sannotations_shared group by period order by dt desc;
