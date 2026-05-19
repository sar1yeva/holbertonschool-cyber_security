#!/usr/bin/env ruby

require 'optparse'

TASK_FILE = 'tasks.txt'

def load_tasks
  return [] unless File.exist?(TASK_FILE)
  File.readlines(TASK_FILE, chomp: true)
end

def save_tasks(tasks)
  File.write(TASK_FILE, tasks.join("\n"))
end

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: cli.rb [options]"

  opts.on("-a TASK", "--add TASK", "Add a new task") do |task|
    options[:add] = task
  end

  opts.on("-l", "--list", "List all tasks") do
    options[:list] = true
  end

  opts.on("-r INDEX", "--remove INDEX", "Remove a task by index") do |index|
    options[:remove] = index.to_i
  end

  opts.on("-h", "--help", "Show help") do
    puts opts
    exit
  end
end.parse!

tasks = load_tasks

if options[:add]
  tasks << options[:add]
  save_tasks(tasks)
  puts "Task '#{options[:add]}' added."

elsif options[:list]
  puts "Tasks:"
  tasks.each do |task|
    puts task
  end

elsif options[:remove]
  index = options[:remove] - 1

  if index >= 0 && index < tasks.length
    removed = tasks.delete_at(index)
    save_tasks(tasks)
    puts "Task '#{removed}' removed."
  end
end
