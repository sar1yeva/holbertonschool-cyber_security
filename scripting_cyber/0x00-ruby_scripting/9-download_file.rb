#!/usr/bin/env ruby

require 'open-uri'
require 'uri'
require 'fileutils'

if ARGV.length != 2
  puts "Usage: 9-download_file.rb URL LOCAL_FILE_PATH"
  exit
end

url = ARGV[0]
output_path = ARGV[1]

begin
  puts "Downloading file from #{url}..."

  URI.open(url) do |file|
    FileUtils.mkdir_p(File.dirname(output_path)) unless File.dirname(output_path) == "."

    File.open(output_path, "wb") do |output|
      output.write(file.read)
    end
  end

  puts "File downloaded and saved to #{output_path}."

rescue StandardError => e
  puts "Error: #{e.message}"
end
