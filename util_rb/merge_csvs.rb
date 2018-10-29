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
      h.each do |k,v|
        next if k == 'f' || k == 't' || k == 'rel'
        data[k] = {} unless data.key?(k)
        data[k][dt] = {} unless data[k].key?(dt)
        data[k][dt][arg] = v
        dates[dt] = 1
        keys[k] = 1
      end
    end
  end
  hdr = ['month'] + args.sort
  keys.keys.sort.each do |k|
    fn = "csv/#{k}_monthly.csv"
    CSV.open(fn, 'w', headers: hdr) do |csv|
      csv << hdr
      dates.keys.sort.each do |dt|
        ary = [dt]
        args.sort.each do |arg|
          v = data[k][dt][arg]
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
