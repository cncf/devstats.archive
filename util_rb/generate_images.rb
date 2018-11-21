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
  # This program requires puppeteer, install via `npm i puppeteer`.
  # urls data - array of URL generators
  #   urls data row: array
  #     1st item: [url root, [only], [skip]
  #       only: array of projects to use this url, all projects if empty
  #       skip: array of projects not using this url, none if empty
  #     2nd, 3rd ... (all remaining items): params to replace
  #       each param: [name, [values]]
  #         param name: [[name]] will be replaced with its value
  #         [[name]] will be replaced by all [values] from array
  #     If more than 1 param, all cartesian combinations will be used
  urls_data = [
    [
      [
        'https://[[project]].devstats.cncf.io/d/48/users-stats?orgId=1&var-period=[[period]]&var-metric=[[metric]]&var-repogroup_name=All&var-users=All&from=[[from]]&to=[[to]]',
        [],
        ['k8s'],
      ],
      ['period', ['d7', 'w', 'm']],
      ['metric', ['issues', 'prs', 'commits', 'contributions', 'comments']],
    ],
    [
      [
        'https://[[project]].devstats.cncf.io/d/8/company-statistics-by-repository-group?orgId=1&var-period=[[period]]&var-metric=[[metric]]&var-repogroup_name=All&var-companies=All&from=[[from]]&to=[[to]]',
        ['k8s'],
        [],
      ],
      ['period', ['w', 'm']],
      ['metric', ['authors', 'issues', 'prs', 'commits', 'contributions', 'contributors', 'comments']],
    ],
  ]
  # puppeteer code to generate images
  js_code = """
  const puppeteer = require('puppeteer');
  (async () => {
    const browser = await puppeteer.launch({headless: true, args:['--no-sandbox']});
    const page = await browser.newPage();
    await page.goto('[[url]]');
    await page.screenshot({path: '/var/www/html/img/projects/[[image]]'});
    await browser.close();
  })();
  """
  js_fn = './util_js/temp.js'
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
      url_root = url_root.gsub('[[project]]', name)
      url_root = url_root.gsub('[[from]]', dts)
      url_root = url_root.gsub('[[to]]', nows)
      params = {}
      url_data[1..-1].each do |param_data|
        param = param_data[0]
        param_values = param_data[1]
        params[param] = param_values unless params.key?(param)
      end
      params = make_cartesian(params)
      params[1].each do |values|
        url = url_root
        img = name
        params[0].each_with_index do |param, i|
          value = values[i]
          url = url.gsub('[[' + param + ']]', value)
          img += "-" + param + '-' + value
        end
        img += '.png'
        js = js_code.gsub('[[url]]', url)
        js = js.gsub('[[image]]', img)
        File.write(js_fn, js)
        t1 = Time.now
        res = `node #{js_fn}`
        if res != ''
          puts "Error for #{img}: #{res}\nCode:\n#{js}\n"
          exit 1
        end
        t2 = Time.now
        tm = t2 - t1
        puts "#{img} generated: time: #{tm}"
        binding.pry
      end
    end
  end
end

generate_images
