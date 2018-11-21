#!/usr/bin/env ruby

require 'yaml'
require 'etc'
require 'timeout'
require 'pry'

# input { 'par1': [values1], 'par2': [values2], ... }
# output: [ [par1, par2, ...], [[par1valI, par2ValI, ...], [par1valJ, par2ValJ, ...], ...]
# returns all possible parameters combinations
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
  # default periods and metrics for given dashboards
  periods = ['d7', 'w', 'm']
  companies_metrics = ['authors', 'issues', 'prs', 'commits', 'contributions', 'contributors', 'comments']
  users_metrics = ['issues', 'prs', 'commits', 'contributions', 'comments']
  urls_data = [
    [
      [
        'users-stats',
        'https://[[project]].devstats.cncf.io/d/48/users-stats?orgId=1&var-period=[[period]]&var-metric=[[metric]]&var-repogroup_name=All&var-users=All&from=[[from]]&to=[[to]]',
        [],
        ['k8s'],
      ],
      ['period', periods],
      ['metric', users_metrics],
    ],
    [
      [
        'companies-stats',
        'https://[[project]].devstats.cncf.io/d/8/company-statistics-by-repository-group?orgId=1&var-period=[[period]]&var-metric=[[metric]]&var-repogroup_name=All&var-companies=All&from=[[from]]&to=[[to]]',
        ['k8s'],
        [],
      ],
      ['period', periods],
      ['metric', companies_metrics],
    ],
    [
      [
        'companies-stats',
        'https://[[project]].teststats.cncf.io/d/4/companies-stats?orgId=1&from=[[from]]&to=[[to]]&var-period=[[period]]&var-metric=[[metric]]&var-repogroup_name=All&var-companies=All',
        [],
        ['k8s'],
      ],
      ['period', periods],
      ['metric', companies_metrics],
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
  pdebug = false # debug processes
  idebug = true # debug image generation
  js_fn = './util_js/[[name]]_[[pid]].js'
  itype = 'jpeg'
  timeout_seconds = 60 # time to finish puppeteer sub processes
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
    # skip disabled projects
    disabled = project[1]['disabled']
    next if disabled
    start_dt = project[1]['start_date']
    join_dt = project[1]['join_date']
    # skip projects which doesn't have CNCF join date
    next unless join_dt
    now = Time.now
    now3m = now - 10540800
    join_ago = now - join_dt
    # try to have join date at the half of date period
    # but don't start earlier than project start date
    # with the exception that start date must be at least 3 months ago
    dt = join_dt - join_ago
    dt = start_dt if dt < start_dt
    dt = now3m if dt > now3m
    dt_ago = now - dt
    # end date will be now - aggregation period length
    # join_perc is the position of CNCF join date withing start - end dates period
    join_perc = 1. - join_ago / dt_ago
    dts = (dt.to_i * 1000).to_s
    nows = (now.to_i * 1000).to_s
    urls_data.each do |url_data|
      url_name = url_data[0][0] # name root for this dashboard
      url_root = url_data[0][1] # its url with [[params]] encoded
      only = url_data[0][2]
      skip = url_data[0][3]
      next if only.count > 0 && !only.include?(name)  # this url is only for some dashboards
      next if skip.count > 0 && skip.include?(name)   # this url should not be used for some dashboards
      url_root = url_root.gsub('[[project]]', name)
      url_root = url_root.gsub('[[from]]', dts)
      params = {}
      url_data[1..-1].each do |param_data|
        param = param_data[0]
        param_values = param_data[1]
        params[param] = param_values unless params.key?(param)
      end
      # [[params]] to replace
      params = make_cartesian(params) # make a cartesian product with all possible params combinations
      params[1].each do |values|
        # values array of a current combination of params values
        njoin_perc = join_perc
        url = url_root
        img = name + '-' + url_name # projname-dashboard-name
        to_replaced = false
        params[0].each_with_index do |param, i|
          # param - ith param
          value = values[i] # i-th param value from current combination
          url = url.gsub('[[' + param + ']]', value)
          img += "-" + param + '-' + value # += period-w or metric-contributors etc.
          if param == 'period'
            # move end date back when applying param, one week back for w, one month back for m etc.
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
            # recalculate relative CNCF join date vertical line for new date range from - (now - period)
            join_ago = tend - join_dt
            dt_ago = tend - dt
            njoin_perc = 1. - join_ago / dt_ago
            tends = (tend.to_i * 1000).to_s
            to_replaced = true
            url = url.gsub('[[to]]', tends)
          end
        end
        # if there was no period param, date to is just now
        url = url.gsub('[[to]]', nows) unless to_replaced
        js = js_code.gsub('[[url]]', url)
        js = js.gsub('[[image]]', img + '.' + itype)
        js = js.gsub('[[join]]', njoin_perc.to_s)
        # fork to run node processes, do not fork more than number of CPUs available
        pid = fork do
          fn = js_fn.gsub('[[pid]]', Process.pid.to_s)
          fn = fn.gsub('[[name]]', img)
          File.write(fn, js)
          t1 = Time.now
          # Execute node/puppeteer for generated JS code
          res = `node #{fn}`
          if res != ''
            puts "Error for #{img}: #{res}\nCode (#{fn}):\n#{js}\n"
            exit 1
          end
          File.delete(fn)
          t2 = Time.now
          tm = t2 - t1
          puts "#{img} generated: time: #{tm}" if idebug
          exit 0
        end
        pids << pid
        # Guard number of forks and wait when == number of CPUs
        if pids.count >= maxProc
          pid = pids[0]
          pids = pids[1..-1]
          begin
            # give timeout_seconds (60) seconds to finish
            Timeout::timeout(timeout_seconds) do
              Process.wait pid
              puts "Finished #{pid}" if pdebug
            end
          rescue Timeout::Error
            puts "Timeout #{pid}"
            Process.kill('KILL', pid)
          end
        end
        # binding.pry
      end
    end
  end
  # cleasnup and wait for all subprocesses to finish
  puts 'Finished, waiting for children' if pdebug
  pids.each do |pid|
    begin
      Timeout::timeout(60) do
        Process.wait pid
        puts "Finished #{pid}" if pdebug
      end
    rescue Timeout::Error
      puts "Timeout #{pid}"
      Process.kill('KILL', pid)
    end
  end
  # final stats
  te = Time.now
  tm = te - ts
  puts "All images generated, time: #{tm}"
end

generate_images
