#!/usr/bin/env ruby

def print_arguments
  puts "Arguments:"
  puts

  ARGV.each do |arg|
    puts arg
  end
end

print_arguments
