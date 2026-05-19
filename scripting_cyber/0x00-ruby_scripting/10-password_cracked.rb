#!/usr/bin/env ruby

require 'digest'

if ARGV.length != 2
  puts "Usage: 10-password_cracked.rb HASHED_PASSWORD DICTIONARY_FILE"
  exit
end

hashed_password = ARGV[0]
dictionary_file = ARGV[1]

begin
  File.foreach(dictionary_file) do |line|
    word = line.strip
    next if word.empty?

    hash = Digest::SHA256.hexdigest(word)

    if hash == hashed_password
      puts "Password found: #{word}"
      exit
    end
  end

  puts "Password not found in dictionary."

rescue Errno::ENOENT
  puts "Error: File not found."
end
