require 'pry'
require 'csv'
  
def merge_csvs(args)
  data = {}
  dates = {}
  keys = {}
  args.each do |arg|
    fn = "csv/#{arg}_monthly_data.csv"
    CSV.foreach(fn, headers: true) do |row|
      h = row.to_h
      dt = h['rel']
      ddt = DateTime.strptime(dt, '%m/%Y')
      h.each do |k,v|
        next if k == 'f' || k == 't' || k == 'rel'
        data[k] = {} unless data.key?(k)
        data[k][ddt] = {} unless data[k].key?(ddt)
        data[k][ddt][arg] = v
        dates[ddt] = 1
        keys[k] = 1
      end
    end
  end
  hdr = ['month'] + args.sort
  keys.keys.sort.each do |k|
    fn = "csv/#{k}_monthly.csv"
    CSV.open(fn, 'w', headers: hdr) do |csv|
      csv << hdr
      dates.keys.sort.each do |ddt|
        ary = [ddt.strftime("%m/%Y")]
        args.sort.each do |arg|
          v = data[k][ddt][arg]
          v = 0 if v.nil? || v == ''
          ary << v
        end
        csv << ary
      end
    end
  end
end

if ARGV.size < 2
  puts "Missing arguments"
  exit(1)
end

merge_csvs(ARGV)
