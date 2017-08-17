require 'date'
require 'time'

def seconds_in_day
  3600 * 24
end

def seconds_in_week
  seconds_in_day * 7
end

def day_start(dt)
  dt.to_date.to_time
end

def next_day_start(dt)
  day_start dt + seconds_in_day
end

def next_month_start(dt)
  y = dt.year
  m = dt.month
  m += 1
  if m > 12
    m = 1
    y += 1
  end
  Time.new y, m
end

def next_year_start(dt)
  Time.new dt.year + 1
end

def week_start(dt)
  day_start dt - ((dt.wday - 1) % 7) * seconds_in_day
end

def next_week_start(dt)
  week_start dt + seconds_in_week
end

def month_start(dt)
  Time.new dt.year, dt.month
end

def year_start(dt)
  Time.new dt.year
end

def to_ymd(dt)
  dt.strftime '%Y-%m-%d'
end
