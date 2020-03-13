select
  {{exclude_bots}} as exclude,
  {{range}} as range,
  {{project_scale}} as project_scale,
  {{from}} as sfrom,
  {{to}} as sto,
  {{period:now()}} as period,
  {{period}} as period2,
  {{n}} as n,
  {{lim}} as lim
;
