#!/usr/bin/env ruby

require "json"
require "net/http"
require "openssl"
require "time"
require "uri"

automate_url = ENV["AUTOMATE_URL"]
automate_token = ENV["AUTOMATE_TOKEN"]

if automate_url.nil?
  puts "You must provide an AUTOMATE_URL environment variable."
  exit 1
end

if automate_token.nil?
  puts "You must provide an AUTOMATE_TOKEN environment variable."
  exit 1
end

if ARGV[0].nil?
  days = 1
else
  days = ARGV[0].to_i
end

# JSON is the default
if ARGV[1].nil?
  type = "json"
elsif ARGV[1].downcase.eql?("csv")
  type = "csv"
else
  type = "json"
end

body = { "type" => "#{type}",
        "filters": [
          { "type": "end_time", "values": ["#{Time.now.utc.iso8601}"] },
          { "type": "start_time", "values": ["#{(Time.now - (days * 86400)).utc.iso8601}"] },
        ] }

unless ARGV[2].nil?
  filters = eval(ARGV[2])
  filters.each do |filter|
    f = { type: filter.keys[0].to_s, values: filter.values[0] }
    body[:filters].push(f)
  end
end

# https://docs.chef.io/automate/api/#operation/Export
uri = URI.parse("#{automate_url}/api/v0/compliance/reporting/export")

req_options = {
               use_ssl: uri.scheme == "https",
               verify_mode: OpenSSL::SSL::VERIFY_NONE,
              }
request = Net::HTTP::Post.new(uri)
request["Api-Token"] = automate_token
request.body = body.to_json

response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end

if type.eql?("csv")
  require "csv"
  table = CSV::Table.new(CSV.parse(response.body, headers: true))
  ARGV[3..-1].each do |col| # remove columns by header
    table.delete(col)
  end
  puts table.to_csv
else
  puts response.body
end
