#!/usr/bin/env ruby

def print_arguments
  args = ARGV

  puts "Arguments:"

  if args.empty?
    return
  end

  args.each do |arg|
    puts arg
  end
end

print_arguments
