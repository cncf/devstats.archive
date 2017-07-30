#!/usr/bin/env ruby

require 'json'
require 'pry'

# Outputs object structure (without data), to compare if different objects are representing similar data
# s: output string
# o: object
# is: ignore scalars: true ==> will not output data types, false => will output values data type
# md: max depth (recursion depth), 1 will only search top level fields, 2 will look in one level deeper etc
# d: current depth (used automatically in recursion)
def object_structure(s, o, is=false, md=nil, d=0)
  case o
  when Hash
    if !md || d < md
      s += '{'
      o.keys.sort.each do |k|
        v = o[k]
        s += k.to_s + ':' + object_structure('', v, is, md, d + 1)
        s += ','
      end
      s = s[0..-2] + '}'
    else
      s += '{}'
    end
  when Array
    if !md || d < md
      v = o.first
      s += '[' + object_structure('', v, is, md, d + 1) + ']'
      nd = o.map(&:class).uniq.count
      if nd >= 2
        puts "Non unique type array elements"
        p o
        binding.pry
      end
    else
      s += '[]'
    end
  when NilClass
    s += '(nil)' unless is
  when TrueClass, FalseClass
    s += '(bool)' unless is
  when String
    s += '(string)' unless is
  when Symbol
    s += '(symbol)' unless is
  when Fixnum
    s += '(fixnum)' unless is
  when Bignum
    s += '(bignum)' unless is
  when Float
    s += '(float)' unless is
  when Time, Date, DateTime
    s += '(dt)' unless is
  else
    puts "Unknown class #{o.class}"
    exit 1
  end
  s
end


# Analysis of JSON data to determine PSQL tables to create
def analysis(jsons)
  n = 0
  occ = {}
  ml = {}
  strs = {}
  jsons.each do |json|
    h = JSON.parse(File.read(json)).to_h
    # Leave h "as is" to investigate top level DB table
    # h = h['actor']      # Investigate gha_actors table
    # h = h['repo']       # Investigate gha_repos table
    # h = h['org']        # Investigate gha_orgs table
    h = h['payload']    # Investigate gha_payloads table (most complex)
    next unless h
    # h = h['issue']
    # next unless h
    s = object_structure('', h, true, 1)
    strs[s] = h

    # Analysis
    keys = h.keys
    classes = h.values.map(&:class).map(&:name)
    h.each do |k, v|
      vl = v.to_s.length
      ml[k] = vl if !ml.key?(k) || ml[k] < vl
    end
    keys.zip(classes).each do |k, c|
      kc = k + ':' + c
      occ[kc] = 0 unless occ.key?(kc)
      occ[kc] += 1
    end
    n += 1
  end
  p occ
  p ml
  p n
  binding.pry if strs.keys.length > 1
end

analysis(ARGV)

# gha_events: {"id:String"=>48592, "type:String"=>48592, "actor:Hash"=>48592, "repo:Hash"=>48592, "payload:Hash"=>48592, "public:TrueClass"=>48592, "created_at:String"=>48592, "org:Hash"=>19451}
# gha_actors: {"id:Fixnum"=>48592, "login:String"=>48592, "display_login:String"=>48592, "gravatar_id:String"=>48592, "url:String"=>48592, "avatar_url:String"=>48592}
# gha_repos: {"id:Fixnum"=>48592, "name:String"=>48592, "url:String"=>48592}
# gha_orgs: {"id:Fixnum"=>18494, "login:String"=>18494, "gravatar_id:String"=>18494, "url:String"=>18494, "avatar_url:String"=>18494}
# gha_payloads: {"push_id:Fixnum"=>24636, "size:Fixnum"=>24636, "distinct_size:Fixnum"=>24636, "ref:String"=>30522, "head:String"=>24636, "before:String"=>24636, "commits:Array"=>24636, "action:String"=>14317, "issue:Hash"=>6446, "comment:Hash"=>6055, "ref_type:String"=>8010, "master_branch:String"=>6724, "description:String"=>3701, "pusher_type:String"=>8010, "pull_request:Hash"=>4475, "ref:NilClass"=>2124, "description:NilClass"=>3023, "number:Fixnum"=>2992, "forkee:Hash"=>1211, "pages:Array"=>370, "release:Hash"=>156, "member:Hash"=>219}
# gha_commits: {"sha:String"=>23265, "author:Hash"=>23265, "message:String"=>23265, "distinct:TrueClass"=>21789, "url:String"=>23265, "distinct:FalseClass"=>1476}
