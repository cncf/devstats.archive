require 'date'
require 'time'

def seconds_in_day
  3600 * 24
end

def seconds_in_week
  seconds_in_day * 7
end

def hour_start(dt)
  Time.new(
    dt.year,
    dt.month,
    dt.day,
    dt.hour
  ).utc
end

def day_start(dt)
  dt.to_date.to_time.utc
end

def week_start(dt)
  day_start dt - ((dt.wday - 1) % 7) * seconds_in_day
end

def month_start(dt)
  Time.new(dt.year, dt.month).utc
end

def quarter_start(dt)
  Time.new(
    dt.year,
    ((dt.month - 1) / 3) * 3 + 1
  ).utc
end

def year_start(dt)
  Time.new(dt.year).utc
end

def next_hour_start(dt)
  hour_start dt + 3600
end

def next_day_start(dt)
  day_start dt + seconds_in_day
end

def next_week_start(dt)
  week_start dt + seconds_in_week
end

def next_n_month_start(dt, n)
  y = dt.year
  m = dt.month
  m += n
  if m > 12
    m -= 12
    y += 1
  end
  Time.new(y, m).utc
end

def next_month_start(dt)
  next_n_month_start dt, 1
end

def next_quarter_start(dt)
  next_n_month_start dt, 3
end

def next_year_start(dt)
  Time.new(dt.year + 1).utc
end

def to_ymd(dt)
  dt.strftime '%Y-%m-%d'
end

def to_ymdhms(dt)
  dt.strftime '%Y-%m-%d %H:%M:%S'
end
