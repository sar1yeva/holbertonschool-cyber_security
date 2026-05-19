#!/usr/bin/env ruby
def print_arguments
  args = ARGV

  puts "Arguments:"

  args.each do |arg|
    puts arg
  end
end
