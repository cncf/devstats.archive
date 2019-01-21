with commits as (
  select r.repo_group as repo_group,
    c.sha,
    c.dup_created_at as created_at,
    c.{{user}}_id as user_id
  from
    gha_commits c,
    gha_repos r
  where
    {{period:c.dup_created_at}}
    and (lower(c.dup_{{user}}_login) {{exclude_bots}})
    and c.dup_repo_id = r.id
    and c.dup_repo_name = r.name
    and r.repo_group is not null
    and r.repo_group in (
      'Buildpacks', 'CloudEvents', 'containerd', 'CoreDNS', 'Cortex', 'Dragonfly', 'Envoy',
      'etcd', 'Falco', 'Fluentd', 'gRPC', 'Harbor', 'Helm', 'Jaeger', 'Kubernetes', 'Linkerd',
      'NATS', 'Notary', 'OPA', 'OpenMetrics', 'OpenTracing', 'Prometheus', 'rkt', 'Rook',
      'SPIFFE', 'SPIRE', 'Telepresence', 'TiKV', 'TUF', 'Virtual Kubelet', 'Vitess'
    )
    and r.repo_group not in ({{skip_repo_groups}})
), company_commits as (
  select i.repo_group,
    i.sha,
    i.company
  from (
    select c.repo_group,
      c.sha,
      coalesce(aa.company_name, '*unknown*') as company
    from
      commits c
    left join
      gha_actors_affiliations aa
    on
      aa.actor_id = c.user_id
      and aa.dt_from <= c.created_at
      and aa.dt_to > c.created_at
  ) i
  where
    i.company not in ({{skip_companies}})
), all_commits as (
  select count(distinct sha) as cnt
  from
    company_commits
), by_repo_and_company as (
  select repo_group,
    company,
    count(distinct sha) as cnt
  from
    company_commits
  group by
    repo_group,
    company
  order by
    cnt desc
), by_company as (
  select company,
    count(distinct sha) as cnt
  from
    company_commits
  group by
    company
  order by
    cnt desc
), by_repo as (
  select repo_group,
    count(distinct sha) as cnt
  from
    company_commits
  group by
    repo_group
  order by
    cnt desc
), top_companies as (
  select
    'By companies' as t,
    'All companies' as name,
    i.com1 || ': ' || round((i.cnt1::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "1st",
    i.com2 || ': ' || round((i.cnt2::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "2nd",
    i.com3 || ': ' || round((i.cnt3::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "3rd",
    i.com4 || ': ' || round((i.cnt4::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "4th",
    i.com5 || ': ' || round((i.cnt5::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "5th",
    i.com6 || ': ' || round((i.cnt6::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "6th",
    i.com7 || ': ' || round((i.cnt7::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "7th",
    i.com8 || ': ' || round((i.cnt8::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "8th",
    i.com9 || ': ' || round((i.cnt9::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "9th",
    i.com10 || ': ' || round((i.cnt10::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "10th",
    round(((i.cnt1::numeric+i.cnt2::numeric) / a.cnt::numeric) * 100.0, 2) as top2_percent,
    round(((i.cnt1::numeric+i.cnt2::numeric+i.cnt3::numeric) / a.cnt::numeric) * 100.0, 2) as top3_percent,
    round(((i.cnt1::numeric+i.cnt2::numeric+i.cnt3::numeric+i.cnt4::numeric) / a.cnt::numeric) * 100.0, 2) as top4_percent,
    round(((i.cnt1::numeric+i.cnt2::numeric+i.cnt3::numeric+i.cnt4::numeric+i.cnt5::numeric) / a.cnt::numeric) * 100.0, 2) as top5_percent,
    round(((i.cnt1::numeric+i.cnt2::numeric+i.cnt3::numeric+i.cnt4::numeric+i.cnt5::numeric+i.cnt6::numeric+i.cnt7::numeric+i.cnt8::numeric+i.cnt9::numeric+i.cnt10::numeric) / a.cnt::numeric) * 100.0, 2) as top10_percent
    from (
      select distinct coalesce(nth_value(cnt, 1) over repo_groups_by_commits, 0) as cnt1,
        coalesce(nth_value(repo_group, 1) over repo_groups_by_commits, '') as com1,
        coalesce(nth_value(cnt, 2) over repo_groups_by_commits, 0) as cnt2,
        coalesce(nth_value(repo_group, 2) over repo_groups_by_commits, '') as com2,
        coalesce(nth_value(cnt, 3) over repo_groups_by_commits, 0) as cnt3,
        coalesce(nth_value(repo_group, 3) over repo_groups_by_commits, '') as com3,
        coalesce(nth_value(cnt, 4) over repo_groups_by_commits, 0) as cnt4,
        coalesce(nth_value(repo_group, 4) over repo_groups_by_commits, '') as com4,
        coalesce(nth_value(cnt, 5) over repo_groups_by_commits, 0) as cnt5,
        coalesce(nth_value(repo_group, 5) over repo_groups_by_commits, '') as com5,
        coalesce(nth_value(cnt, 6) over repo_groups_by_commits, 0) as cnt6,
        coalesce(nth_value(repo_group, 6) over repo_groups_by_commits, '') as com6,
        coalesce(nth_value(cnt, 7) over repo_groups_by_commits, 0) as cnt7,
        coalesce(nth_value(repo_group, 7) over repo_groups_by_commits, '') as com7,
        coalesce(nth_value(cnt, 8) over repo_groups_by_commits, 0) as cnt8,
        coalesce(nth_value(repo_group, 8) over repo_groups_by_commits, '') as com8,
        coalesce(nth_value(cnt, 9) over repo_groups_by_commits, 0) as cnt9,
        coalesce(nth_value(repo_group, 9) over repo_groups_by_commits, '') as com9,
        coalesce(nth_value(cnt, 10) over repo_groups_by_commits, 0) as cnt10,
        coalesce(nth_value(repo_group, 10) over repo_groups_by_commits, '') as com10
      from
        by_repo
      window
        repo_groups_by_commits as (
          order by
            cnt desc
          range between unbounded preceding
          and unbounded following
        )
    ) i, (
      select cnt
      from
        all_commits
    ) a
  union select
    'By companies' as t,
    i.company as name,
    i.com1 || ': ' || round((i.cnt1::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "1st",
    i.com2 || ': ' || round((i.cnt2::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "2nd",
    i.com3 || ': ' || round((i.cnt3::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "3rd",
    i.com4 || ': ' || round((i.cnt4::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "4th",
    i.com5 || ': ' || round((i.cnt5::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "5th",
    i.com6 || ': ' || round((i.cnt6::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "6th",
    i.com7 || ': ' || round((i.cnt7::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "7th",
    i.com8 || ': ' || round((i.cnt8::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "8th",
    i.com9 || ': ' || round((i.cnt9::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "9th",
    i.com10 || ': ' || round((i.cnt10::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "10th",
    round(((i.cnt1::numeric+i.cnt2::numeric) / a.cnt::numeric) * 100.0, 2) as top2_percent,
    round(((i.cnt1::numeric+i.cnt2::numeric+i.cnt3::numeric) / a.cnt::numeric) * 100.0, 2) as top3_percent,
    round(((i.cnt1::numeric+i.cnt2::numeric+i.cnt3::numeric+i.cnt4::numeric) / a.cnt::numeric) * 100.0, 2) as top4_percent,
    round(((i.cnt1::numeric+i.cnt2::numeric+i.cnt3::numeric+i.cnt4::numeric+i.cnt5::numeric) / a.cnt::numeric) * 100.0, 2) as top5_percent,
    round(((i.cnt1::numeric+i.cnt2::numeric+i.cnt3::numeric+i.cnt4::numeric+i.cnt5::numeric+i.cnt6::numeric+i.cnt7::numeric+i.cnt8::numeric+i.cnt9::numeric+i.cnt10::numeric) / a.cnt::numeric) * 100.0, 2) as top10_percent
  from (
      select distinct company,
        coalesce(nth_value(cnt, 1) over repo_groups_by_commits, 0) as cnt1,
        coalesce(nth_value(repo_group, 1) over repo_groups_by_commits, '') as com1,
        coalesce(nth_value(cnt, 2) over repo_groups_by_commits, 0) as cnt2,
        coalesce(nth_value(repo_group, 2) over repo_groups_by_commits, '') as com2,
        coalesce(nth_value(cnt, 3) over repo_groups_by_commits, 0) as cnt3,
        coalesce(nth_value(repo_group, 3) over repo_groups_by_commits, '') as com3,
        coalesce(nth_value(cnt, 4) over repo_groups_by_commits, 0) as cnt4,
        coalesce(nth_value(repo_group, 4) over repo_groups_by_commits, '') as com4,
        coalesce(nth_value(cnt, 5) over repo_groups_by_commits, 0) as cnt5,
        coalesce(nth_value(repo_group, 5) over repo_groups_by_commits, '') as com5,
        coalesce(nth_value(cnt, 6) over repo_groups_by_commits, 0) as cnt6,
        coalesce(nth_value(repo_group, 6) over repo_groups_by_commits, '') as com6,
        coalesce(nth_value(cnt, 7) over repo_groups_by_commits, 0) as cnt7,
        coalesce(nth_value(repo_group, 7) over repo_groups_by_commits, '') as com7,
        coalesce(nth_value(cnt, 8) over repo_groups_by_commits, 0) as cnt8,
        coalesce(nth_value(repo_group, 8) over repo_groups_by_commits, '') as com8,
        coalesce(nth_value(cnt, 9) over repo_groups_by_commits, 0) as cnt9,
        coalesce(nth_value(repo_group, 9) over repo_groups_by_commits, '') as com9,
        coalesce(nth_value(cnt, 10) over repo_groups_by_commits, 0) as cnt10,
        coalesce(nth_value(repo_group, 10) over repo_groups_by_commits, '') as com10
    from
      by_repo_and_company
    window
      repo_groups_by_commits as (
        partition by company
        order by
          cnt desc
        range between unbounded preceding
        and unbounded following
      )
  ) i, (
    select company,
      cnt
    from
      by_company
    order by
      cnt desc
    limit 70
  ) a
  where
    i.company = a.company
  union select
    'By repo groups' as t,
    i.repo_group as name,
    i.com1 || ': ' || round((i.cnt1::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "1st",
    i.com2 || ': ' || round((i.cnt2::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "2nd",
    i.com3 || ': ' || round((i.cnt3::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "3rd",
    i.com4 || ': ' || round((i.cnt4::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "4th",
    i.com5 || ': ' || round((i.cnt5::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "5th",
    i.com6 || ': ' || round((i.cnt6::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "6th",
    i.com7 || ': ' || round((i.cnt7::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "7th",
    i.com8 || ': ' || round((i.cnt8::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "8th",
    i.com9 || ': ' || round((i.cnt9::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "9th",
    i.com10 || ': ' || round((i.cnt10::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "10th",
    round(((i.cnt1::numeric+i.cnt2::numeric) / a.cnt::numeric) * 100.0, 2) as top2_percent,
    round(((i.cnt1::numeric+i.cnt2::numeric+i.cnt3::numeric) / a.cnt::numeric) * 100.0, 2) as top3_percent,
    round(((i.cnt1::numeric+i.cnt2::numeric+i.cnt3::numeric+i.cnt4::numeric) / a.cnt::numeric) * 100.0, 2) as top4_percent,
    round(((i.cnt1::numeric+i.cnt2::numeric+i.cnt3::numeric+i.cnt4::numeric+i.cnt5::numeric) / a.cnt::numeric) * 100.0, 2) as top5_percent,
    round(((i.cnt1::numeric+i.cnt2::numeric+i.cnt3::numeric+i.cnt4::numeric+i.cnt5::numeric+i.cnt6::numeric+i.cnt7::numeric+i.cnt8::numeric+i.cnt9::numeric+i.cnt10::numeric) / a.cnt::numeric) * 100.0, 2) as top10_percent
  from (
      select distinct repo_group,
        coalesce(nth_value(cnt, 1) over companies_by_commits, 0) as cnt1,
        coalesce(nth_value(company, 1) over companies_by_commits, '') as com1,
        coalesce(nth_value(cnt, 2) over companies_by_commits, 0) as cnt2,
        coalesce(nth_value(company, 2) over companies_by_commits, '') as com2,
        coalesce(nth_value(cnt, 3) over companies_by_commits, 0) as cnt3,
        coalesce(nth_value(company, 3) over companies_by_commits, '') as com3,
        coalesce(nth_value(cnt, 4) over companies_by_commits, 0) as cnt4,
        coalesce(nth_value(company, 4) over companies_by_commits, '') as com4,
        coalesce(nth_value(cnt, 5) over companies_by_commits, 0) as cnt5,
        coalesce(nth_value(company, 5) over companies_by_commits, '') as com5,
        coalesce(nth_value(cnt, 6) over companies_by_commits, 0) as cnt6,
        coalesce(nth_value(company, 6) over companies_by_commits, '') as com6,
        coalesce(nth_value(cnt, 7) over companies_by_commits, 0) as cnt7,
        coalesce(nth_value(company, 7) over companies_by_commits, '') as com7,
        coalesce(nth_value(cnt, 8) over companies_by_commits, 0) as cnt8,
        coalesce(nth_value(company, 8) over companies_by_commits, '') as com8,
        coalesce(nth_value(cnt, 9) over companies_by_commits, 0) as cnt9,
        coalesce(nth_value(company, 9) over companies_by_commits, '') as com9,
        coalesce(nth_value(cnt, 10) over companies_by_commits, 0) as cnt10,
        coalesce(nth_value(company, 10) over companies_by_commits, '') as com10
    from
      by_repo_and_company
    window
      companies_by_commits as (
        partition by repo_group
        order by
          cnt desc
        range between unbounded preceding
        and unbounded following
      )
  ) i, (
    select repo_group,
      cnt
    from
      by_repo
  ) a
  where
    i.repo_group = a.repo_group
  union select
    'By repo groups' as t,
    'All CNCF' as name,
    i.com1 || ': ' || round((i.cnt1::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "1st",
    i.com2 || ': ' || round((i.cnt2::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "2nd",
    i.com3 || ': ' || round((i.cnt3::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "3rd",
    i.com4 || ': ' || round((i.cnt4::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "4th",
    i.com5 || ': ' || round((i.cnt5::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "5th",
    i.com6 || ': ' || round((i.cnt6::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "6th",
    i.com7 || ': ' || round((i.cnt7::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "7th",
    i.com8 || ': ' || round((i.cnt8::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "8th",
    i.com9 || ': ' || round((i.cnt9::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "9th",
    i.com10 || ': ' || round((i.cnt10::numeric / a.cnt::numeric) * 100.0, 2)::text || '% ' as "10th",
    round(((i.cnt1::numeric+i.cnt2::numeric) / a.cnt::numeric) * 100.0, 2) as top2_percent,
    round(((i.cnt1::numeric+i.cnt2::numeric+i.cnt3::numeric) / a.cnt::numeric) * 100.0, 2) as top3_percent,
    round(((i.cnt1::numeric+i.cnt2::numeric+i.cnt3::numeric+i.cnt4::numeric) / a.cnt::numeric) * 100.0, 2) as top4_percent,
    round(((i.cnt1::numeric+i.cnt2::numeric+i.cnt3::numeric+i.cnt4::numeric+i.cnt5::numeric) / a.cnt::numeric) * 100.0, 2) as top5_percent,
    round(((i.cnt1::numeric+i.cnt2::numeric+i.cnt3::numeric+i.cnt4::numeric+i.cnt5::numeric+i.cnt6::numeric+i.cnt7::numeric+i.cnt8::numeric+i.cnt9::numeric+i.cnt10::numeric) / a.cnt::numeric) * 100.0, 2) as top10_percent
    from (
      select distinct coalesce(nth_value(cnt, 1) over companies_by_commits, 0) as cnt1,
        coalesce(nth_value(company, 1) over companies_by_commits, '') as com1,
        coalesce(nth_value(cnt, 2) over companies_by_commits, 0) as cnt2,
        coalesce(nth_value(company, 2) over companies_by_commits, '') as com2,
        coalesce(nth_value(cnt, 3) over companies_by_commits, 0) as cnt3,
        coalesce(nth_value(company, 3) over companies_by_commits, '') as com3,
        coalesce(nth_value(cnt, 4) over companies_by_commits, 0) as cnt4,
        coalesce(nth_value(company, 4) over companies_by_commits, '') as com4,
        coalesce(nth_value(cnt, 5) over companies_by_commits, 0) as cnt5,
        coalesce(nth_value(company, 5) over companies_by_commits, '') as com5,
        coalesce(nth_value(cnt, 6) over companies_by_commits, 0) as cnt6,
        coalesce(nth_value(company, 6) over companies_by_commits, '') as com6,
        coalesce(nth_value(cnt, 7) over companies_by_commits, 0) as cnt7,
        coalesce(nth_value(company, 7) over companies_by_commits, '') as com7,
        coalesce(nth_value(cnt, 8) over companies_by_commits, 0) as cnt8,
        coalesce(nth_value(company, 8) over companies_by_commits, '') as com8,
        coalesce(nth_value(cnt, 9) over companies_by_commits, 0) as cnt9,
        coalesce(nth_value(company, 9) over companies_by_commits, '') as com9,
        coalesce(nth_value(cnt, 10) over companies_by_commits, 0) as cnt10,
        coalesce(nth_value(company, 10) over companies_by_commits, '') as com10
      from
        by_company
      window
        companies_by_commits as (
          order by
            cnt desc
          range between unbounded preceding
          and unbounded following
        )
    ) i, (
      select cnt
      from
        all_commits
    ) a
  order by
    t asc,
    name asc
)
select * from  top_companies;
-- select company, count(distinct sha) as cnt from company_commits group by company order by cnt desc limit 50;
