#!/usr/bin/env ruby

def shut_down
  puts "\nWill finish, but after 3 seconds..."
  sleep 1
  puts "---"
  sleep 1
  puts "---"
  sleep 1
  puts "---"
end

puts "I have PID #{Process.pid}"

Signal.trap("INT") {
  shut_down
  exit 1
}

Signal.trap("TERM") {
  shut_down
  exit 2
}

Signal.trap("HUP") {
  shut_down
  exit 3
}

puts "..."
sleep 1
puts "..."
sleep 1
puts "..."
sleep 1
exit 4
