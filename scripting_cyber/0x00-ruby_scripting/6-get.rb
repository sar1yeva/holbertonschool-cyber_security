#!/usr/bin/env ruby

require 'net/http'
require 'uri'

def get_request(url)
  uri = URI.parse(url)

  response = Net::HTTP.get_response(uri)

  puts "Response status: #{response.code} #{response.message}"
  puts "Response body:"
  puts response.body
end
