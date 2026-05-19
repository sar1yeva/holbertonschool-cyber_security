#!/usr/bin/env ruby
require 'optparse'
TASKS_FILE = 'tasks.txt'
def load_tasks
  return [] unless File.exist?(TASKS_FILE)
  File.readlines(TASKS_FILE, chomp: true)
end
def save_tasks(tasks)
  File.write(TASKS_FILE, tasks.join("\n") + (tasks.empty? ? "" : "\n"))
end
def add_task(task)
  tasks = load_tasks
  tasks << task
  save_tasks(tasks)
  puts "Task '#{task}' added."
end
def list_tasks
  tasks = load_tasks
  if tasks.empty?
    puts "No tasks found."
  else
    puts "Tasks:"
    tasks.each_with_index { |task, i| puts "#{i + 1}. #{task}" }
  end
end
def remove_task(index)
  tasks = load_tasks
  i = index.to_i - 1
  if i < 0 || i >= tasks.length
    puts "Invalid index."
    exit 1
  end
  removed = tasks.delete_at(i)
  save_tasks(tasks)
  puts "Task '#{removed}' removed."
end
options = {}
parser = OptionParser.new do |opts|
  opts.banner = "Usage: cli.rb [options]"
  opts.on("-a", "--add TASK", "Add a new task") do |task|
    options[:action] = :add
    options[:task] = task
  end
  opts.on("-l", "--list", "List all tasks") do
    options[:action] = :list
  end
  opts.on("-r", "--remove INDEX", "Remove a task by index") do |index|
    options[:action] = :remove
    options[:index] = index
  end
  opts.on("-h", "--help", "Show help") do
    puts opts
    exit
  end
end
parser.parse!
case options[:action]
when :add    then add_task(options[:task])
when :list   then list_tasks
when :remove then remove_task(options[:index])
else
  puts parser
  exit 1
end
