#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'

def get_request(url)
  uri = URI.parse(url)

  response = Net::HTTP.get_response(uri)

  puts "Response status: #{response.code} #{response.message}"
  puts "Response body:"

  begin
    json = JSON.parse(response.body)
    puts JSON.pretty_generate(json)
  rescue JSON::ParserError
    puts response.body
  end
end
