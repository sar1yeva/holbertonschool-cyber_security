#!/usr/bin/env ruby

require 'json'

def merge_json_files(file1_path, file2_path)
  file1_data = JSON.parse(File.read(file1_path))
  file2_data = JSON.parse(File.read(file2_path))

  merged_data = file2_data + file1_data

  File.write(file2_path, JSON.pretty_generate(merged_data))
end
