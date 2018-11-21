#!/usr/bin/env ruby

require 'yaml'
require 'etc'
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
  #     1st item: [name, url root, [only], [skip]
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
        'users-stats',
        'https://[[project]].devstats.cncf.io/d/48/users-stats?orgId=1&var-period=[[period]]&var-metric=[[metric]]&var-repogroup_name=All&var-users=All&from=[[from]]&to=[[to]]',
        [],
        ['k8s'],
      ],
      ['period', ['d7', 'w', 'm', 'q']],
      ['metric', ['issues', 'prs', 'commits', 'contributions', 'comments']],
    ],
    [
      [
        'companies-stats',
        'https://[[project]].devstats.cncf.io/d/8/company-statistics-by-repository-group?orgId=1&var-period=[[period]]&var-metric=[[metric]]&var-repogroup_name=All&var-companies=All&from=[[from]]&to=[[to]]',
        ['k8s'],
        [],
      ],
      ['period', ['d7', 'w', 'm', 'q']],
      ['metric', ['authors', 'issues', 'prs', 'commits', 'contributions', 'contributors', 'comments']],
    ],
    [
      [
        'companies-stats',
        'https://[[project]].teststats.cncf.io/d/4/companies-stats?orgId=1&from=[[from]]&to=[[to]]&var-period=[[period]]&var-metric=[[metric]]&var-repogroup_name=All&var-companies=All',
        [],
        ['k8s'],
      ],
      ['period', ['d7', 'w', 'm', 'q']],
      ['metric', ['authors', 'issues', 'prs', 'commits', 'contributions', 'contributors', 'comments']],
    ],
  ]

  # puppeteer code to generate images
  # ensures --no-sandbox mode
  # sets bigger viewport
  # hides all annotations and use 1st one to draw line before/after joining CNCF
  # it just manipulates 'left' CSS property of an existing first annotation line
  # finally it captures given chart selector and saves as a jpeg file
  js_code = """
  const puppeteer = require('puppeteer');
  (async () => {
    const browser = await puppeteer.launch({headless: true, args:['--no-sandbox']});
    const page = await browser.newPage();
    page.setViewport({width:[[width]], height:[[height]]});
    await page.goto('[[url]]', {waitUntil: 'networkidle0'});
    await page.evaluate(() => {
      $('.events_line').css('display', 'none');
      $('.events_line:first').css('display', '');
      var left = parseFloat($('.events_line:first').css('left'));
      var right = parseFloat($('.events_line:first').css('right'));
      var sum = left + right;
      var off = [[join]] * sum;
      $('.events_line:first').css('left', off);
    });
    const elementHandle = await page.$('[[selector]]');
    await elementHandle.screenshot({type: '[[type]]', quality: [[qual]], path: '/var/www/html/img/projects/[[image]]'});
    await browser.close();
  })();
  """
  # Config variables
  # width, height, join, type, qual
  js_fn = './util_js/[[name]]_[[pid]].js'
  itype = 'jpeg'
  # was capturing chart panel with legend and header
  # js_code = js_code.gsub('[[selector]]', '.react-grid-item')
  # this captures only chart panel
  js_code = js_code.gsub('[[selector]]', '.graph-panel__chart')
  js_code = js_code.gsub('[[width]]', '1920')
  js_code = js_code.gsub('[[height]]', '1080')
  js_code = js_code.gsub('[[type]]', itype)
  js_code = js_code.gsub('[[qual]]', '85')
  pids = []
  maxProc = Etc.nprocessors

  # Process projects.yaml
  ts = Time.now
  data = YAML.load_file 'projects.yaml'
  data['projects'].each do |project|
    name = project[0]
    name = 'k8s' if name == 'kubernetes'
    disabled = project[1]['disabled']
    next if disabled
    start_dt = project[1]['start_date']
    join_dt = project[1]['join_date']
    next unless join_dt
    now = Time.now
    now3m = now - 10540800
    join_ago = now - join_dt
    dt = join_dt - join_ago
    dt = start_dt if dt < start_dt
    dt = now3m if dt > now3m
    dt_ago = now - dt
    join_perc = 1. - join_ago / dt_ago
    dts = (dt.to_i * 1000).to_s
    nows = (now.to_i * 1000).to_s
    urls_data.each do |url_data|
      url_name = url_data[0][0]
      url_root = url_data[0][1]
      only = url_data[0][2]
      skip = url_data[0][3]
      next if only.count > 0 && !only.include?(name)
      next if skip.count > 0 && skip.include?(name)
      url_root = url_root.gsub('[[project]]', name)
      url_root = url_root.gsub('[[from]]', dts)
      params = {}
      url_data[1..-1].each do |param_data|
        param = param_data[0]
        param_values = param_data[1]
        params[param] = param_values unless params.key?(param)
      end
      params = make_cartesian(params)
      params[1].each do |values|
        njoin_perc = join_perc
        url = url_root
        img = name + '-' + url_name
        to_replaced = false
        params[0].each_with_index do |param, i|
          value = values[i]
          url = url.gsub('[[' + param + ']]', value)
          img += "-" + param + '-' + value
          if param == 'period'
            tend = now
            case value
            when 'd', 'd7'
              tend -= 86400
            when 'w'
              tend -= 604800
            when 'm'
              tend -= 2678400
            when 'q'
              tend -= 7948800
            end
            join_ago = tend - join_dt
            dt_ago = tend - dt
            njoin_perc = 1. - join_ago / dt_ago
            tends = (tend.to_i * 1000).to_s
            to_replaced = true
            url = url.gsub('[[to]]', tends)
          end
        end
        url = url.gsub('[[to]]', nows) unless to_replaced
        js = js_code.gsub('[[url]]', url)
        js = js.gsub('[[image]]', img + '.' + itype)
        js = js.gsub('[[join]]', njoin_perc.to_s)
        pid = fork do
          fn = js_fn.gsub('[[pid]]', Process.pid.to_s)
          fn = fn.gsub('[[name]]', img)
          File.write(fn, js)
          t1 = Time.now
          res = `node #{fn}`
          if res != ''
            puts "Error for #{img}: #{res}\nCode (#{fn}):\n#{js}\n"
            exit 1
          end
          File.delete(fn)
          t2 = Time.now
          tm = t2 - t1
          puts "#{img} generated: time: #{tm}"
          exit 0
        end
        pids << pid
        if pids.count >= maxProc
          pid = pids[0]
          pids = pids[1..-1]
          res = Process.wait pid
        end
        # binding.pry
      end
    end
  end
  pids.each do |pid|
    Process.wait pid
  end
  te = Time.now
  tm = te - ts
  puts "All images generated, time: #{tm}"
end

generate_images
