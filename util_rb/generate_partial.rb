require 'pry'

def generate_partial(outfile, tfile, pfile, tpref, tsuff, ppref, psuff, repl_from, repl_to)
  replaces = repl_from.split(',').map(&:strip)
  tlines = []
  plines = []
  tlines_ws = []
  plines_ws = []
  File.readlines(tfile).each do |line|
    replaces.each { |repl| line = line.gsub(repl, repl_to) }
    sline = line.strip
    i = line.index(sline)
    ws = ''
    ws = line[0..(i-1)] if i > 0
    tlines << sline
    tlines_ws << ws
  end
  File.readlines(pfile).each do |line|
    replaces.each { |repl| line = line.gsub(repl, repl_to) }
    sline = line.strip
    i = line.index(sline)
    ws = ''
    ws = line[0..(i-1)] if i > 0
    plines << sline
    plines_ws << ws
  end
  outlines = []
  outlines_ws = []
  t = 0
  p = 0
  l = 0
  tl = tlines.length
  pl = plines.length
  finished = false
  while !finished
    if tlines[t] == plines[p]
      outlines << tlines[t]
      outlines_ws << tlines_ws[t]
      t += 1
      p += 1
      l += 1
    else
      p_found = false
      pp = p
      while !p_found && pp < pl
        pp += 1
        p_found = true if tlines[t] == plines[pp]
      end
      t_found = false
      tt = t
      while !t_found && tt < tl
        tt += 1
        t_found = true if tlines[tt] == plines[p]
      end
      if !p_found && !t_found
        outlines << "#{tpref}#{tlines[t]}#{tsuff}"
        outlines << "#{ppref}#{plines[t]}#{psuff}"
        outlines_ws << tlines_ws[t]
        outlines_ws << plines_ws[t]
        t += 1
        p += 1
      elsif p_found && !t_found
        for i in p...pp
          outlines << "#{ppref}#{plines[i]}#{psuff}"
          outlines_ws << plines_ws[i]
        end
        outlines << plines[pp]
        outlines_ws << plines_ws[pp]
        t += 1
        p = pp + 1
      elsif !p_found && t_found
        for i in t...tt
          outlines << "#{tpref}#{tlines[i]}#{tsuff}"
          outlines_ws << tlines_ws[i]
        end
        outlines << tlines[tt]
        outlines_ws << tlines_ws[tt]
        p += 1
        t = tt + 1
      elsif p_found && t_found
        for i in p...pp
          outlines << "#{ppref}#{plines[i]}#{psuff}"
          outlines_ws << plines_ws[i]
        end
        for i in t...tt
          outlines << "#{tpref}#{tlines[i]}#{tsuff}"
          outlines_ws << tlines_ws[i]
        end
        outlines << plines[pp]
        outlines << tlines[tt]
        outlines_ws << plines_ws[pp]
        outlines_ws << tlines_ws[tt]
        p = pp + 1
        t = tt + 1
      end
    end
    finished = true if p >= pl && t >= tl
  end
  outlines.each_with_index do |line, idx|
    outlines[idx] = "#{outlines_ws[idx]}#{outlines[idx]}"
  end

  # Write output
  File.write outfile, outlines.join("\n")
end

if ARGV.size < 9
  puts "Missing arguments: partial_file test_file prod_file test_prefix test_suffix prod_prefix prod_suffix 'repl_from1,repl_from2,..,repl_fromN' 'repl_to'"
  exit(1)
end

generate_partial(ARGV[0], ARGV[1], ARGV[2], ARGV[3], ARGV[4], ARGV[5], ARGV[6], ARGV[7], ARGV[8])
