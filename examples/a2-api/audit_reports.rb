#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'openssl'
require 'time'
require 'uri'

automate_url = ENV['AUTOMATE_URL']
automate_token = ENV['AUTOMATE_TOKEN']

if automate_url.nil?
  puts 'You must provide an AUTOMATE_URL environment variable.'
  exit 1
end

if automate_token.nil?
  puts 'You must provide an AUTOMATE_TOKEN environment variable.'
  exit 1
end

# JSON is the default
if ARGV[0].nil?
  type = 'json'
elsif ARGV[0].downcase.eql?('csv')
  type = 'csv'
else
  type = 'json'
end

# https://docs.chef.io/automate/api/#operation/Export
uri = URI.parse("#{automate_url}/api/v0/compliance/reporting/export")

# '{"type":"csv","filters":[{"type":"start_time","values":["2019-09-16T00:00:00Z"]},{"type":"end_time","values":["2019-09-18T23:59:59Z"]}, {"type":"environment","values":["_default"]}]}'
req_options = {
               use_ssl: uri.scheme == "https",
               verify_mode: OpenSSL::SSL::VERIFY_NONE,
              }
request = Net::HTTP::Post.new(uri)
request["Api-Token"] = automate_token
request.body = {
                "type" => "#{type}",
                "filters":[
                           {"type":"end_time","values":["#{Time.now.utc.iso8601}"]},
                           {"type":"start_time","values":["#{(Time.now - 86400).utc.iso8601}"]},
                          ]
               }.to_json

response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end

if type.eql?('csv')
  require 'csv'
  table = CSV::Table.new(CSV.parse(response.body, headers:true))
  ARGV[1..].each do |col| # remove columns by header
    table.delete(col)
  end
  puts table.to_csv
else
  puts response.body
end
