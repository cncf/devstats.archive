#!/usr/bin/env ruby

require 'yaml'
require 'pry'

def make_cartesian(arg)
  key = arg.keys
  values = arg.values
  prod = values[0]
  values[1..-1].each do |value|
    prod = prod.product(value)
  end
  prod.each { |row| row.flatten! }
  [key, prod]
end

def generate_images
  urls_data = [
    [
      [
        'https://[[project]].devstats.cncf.io/d/48/users-stats?orgId=1&var-period=[[period]]&var-metric=[[metric]]&var-repogroup_name=All&var-users=All&from=[[from]]&to=[[to]]',
        [],
        ['k8s'],
      ],
      ['period', ['w', 'm']],
      ['metric', ['activity', 'issues', 'prs', 'commits', 'contributions', 'comments']],
    ],
  ]
  data = YAML.load_file 'projects.yaml'
  data['projects'].each do |project|
    name = project[0]
    name = 'k8s' if name == 'kubernetes'
    start_dt = project[1]['start_date']
    join_dt = project[1]['join_date']
    next unless join_dt
    now = Time.now
    join_ago = now - join_dt
    dt = join_dt - join_ago
    dt = start_dt if dt < start_dt
    dt_ago = now - dt
    join_perc = join_ago / dt_ago
    dts = (dt.to_i * 1000).to_s
    nows = (now.to_i * 1000).to_s
    # p [name, start_dt, dt, join_dt, now, join_perc]
    urls_data.each do |url_data|
      url_root = url_data[0][0]
      only = url_data[0][1]
      skip = url_data[0][2]
      next if only.count > 0 && !only.include?(name)
      next if skip.count > 0 && skip.include?(name)
      url_root = url_root.sub('[[project]]', name)
      url_root = url_root.sub('[[from]]', dts)
      url_root = url_root.sub('[[to]]', nows)
      params = {}
      url_data[1..-1].each do |param_data|
        param = param_data[0]
        param_values = param_data[1]
        params[param] = param_values unless params.key?(param)
      end
      params = make_cartesian(params)
      params[1].each do |values|
        url = url_root
        params[0].each_with_index do |param, i|
          value = values[i]
          url = url.sub('[[' + param + ']]', value)
        end
        p url
      end
    end
  end
end

generate_images
