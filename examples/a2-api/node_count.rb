#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'openssl'
require 'time'
require 'uri'

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

report = {}

# get the failed nodes
uri = URI.parse("#{automate_url}/api/v0/cfgmgmt/nodes?filter=status:failure")
req_options = {
               use_ssl: uri.scheme == "https",
               verify_mode: OpenSSL::SSL::VERIFY_NONE,
              }
request = Net::HTTP::Get.new(uri)
request["Api-Token"] = automate_token
response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end

failed_nodes = JSON.parse(response.body)
failed_nodes.each do |node|
  server = node['source_fqdn']
  org = node['organization']
  report[server] = {} unless report.key?(server)
  report[server][org] = {'total':0, 'successful':0, 'failed':0, 'missing':0} unless report[server].key?(org)
  report[server][org][:total] = report[server][org][:total] + 1
  report[server][org][:failed] = report[server][org][:failed] + 1
end

# get the missing nodes
uri = URI.parse("#{automate_url}/api/v0/cfgmgmt/nodes?filter=status:missing")
req_options = {
               use_ssl: uri.scheme == "https",
               verify_mode: OpenSSL::SSL::VERIFY_NONE,
              }
request = Net::HTTP::Get.new(uri)
request["Api-Token"] = automate_token
response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end

missing_nodes = JSON.parse(response.body)
missing_nodes.each do |node|
  server = node['source_fqdn']
  org = node['organization']
  report[server] = {} unless report.key?(server)
  report[server][org] = {'total':0, 'successful':0, 'failed':0, 'missing':0} unless report[server].key?(org)
  report[server][org][:total] = report[server][org][:total] + 1
  report[server][org][:missing] = report[server][org][:missing] + 1
end

# get the successful nodes
uri = URI.parse("#{automate_url}/api/v0/cfgmgmt/nodes?filter=status:success")
req_options = {
               use_ssl: uri.scheme == "https",
               verify_mode: OpenSSL::SSL::VERIFY_NONE,
              }
request = Net::HTTP::Get.new(uri)
request["Api-Token"] = automate_token
response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end

successful_nodes = JSON.parse(response.body)
successful_nodes.each do |node|
  server = node['source_fqdn']
  org = node['organization']
  report[server] = {} unless report.key?(server)
  report[server][org] = {'total':0, 'successful':0, 'failed':0, 'missing':0} unless report[server].key?(org)
  report[server][org][:total] = report[server][org][:total] + 1
  report[server][org][:successful] = report[server][org][:successful] + 1
end

if ARGV[0].nil?
  json = false
elsif ARGV[0].downcase.eql?('json')
  json = true
end

if json
  require 'json'
  puts JSON.pretty_generate(report) + "\n"
else
  puts "chef-server, organization, total, succeeded, failed, missing"
  report.keys.sort.each do |server|
    report[server].keys.each do |org|
      values = report[server][org]
      puts "#{server}, #{org}, #{values[:total]}, #{values[:successful]}, #{values[:failed]}, #{values[:missing]}"
    end
  end
end
