#!/opt/chef/embedded/bin/ruby

require 'json'
require 'net/http'
require 'openssl'
require 'time'
require 'uri'

automate_url = ENV["AUTOMATE_URL"]
automate_token = ENV["AUTOMATE_TOKEN"]

if automate_url.nil?
  puts "You must 'export AUTOMATE_URL'"
  exit 1
end

if automate_token.nil?
  puts "You must 'export AUTOMATE_TOKEN'"
  exit 1
end

# # get the failed nodes
# uri = URI.parse("#{automate_url}/api/v0/cfgmgmt/nodes?sorting.field=name&sorting.order=ASC&filter=status:failure")

# # get the missing nodes
# uri = URI.parse("#{automate_url}/api/v0/cfgmgmt/nodes?sorting.field=name&sorting.order=ASC&filter=status:missing")

# get the successful nodes
# uri = URI.parse("#{automate_url}/api/v0/cfgmgmt/nodes?sorting.field=name&sorting.order=ASC&filter=status:success")

# all the nodes
uri = URI.parse("#{automate_url}/api/v0/cfgmgmt/nodes?sorting.field=name&sorting.order=ASC")

request = Net::HTTP::Get.new(uri)
request["Api-Token"] = automate_token

req_options = {
               use_ssl: uri.scheme == "https",
               verify_mode: OpenSSL::SSL::VERIFY_NONE,
              }

response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end

nodes = JSON.parse(response.body)

# week as seconds
week = 604800
now = Time.now
one_week_ago = now - week
two_weeks_ago = now - (2 * week)
three_weeks_ago = now - (3 * week)

# 1 week no checkin – alert
alert = []
# 2 week no checkin –amber
amber = []
# 3 week no checkin - red
red = []

one_hour_ago = now - 3600
two_hours_ago = now - 7200
one = []
two = []

nodes.each do |node|
  last_check_in = Time.parse(node['checkin'])
  case
  when three_weeks_ago > last_check_in
    red.push(node)
  when two_weeks_ago > last_check_in
    amber.push(node)
  when one_week_ago > last_check_in
    alert.push(node)
  when two_hours_ago > last_check_in
    two.push(node)
  when one_hour_ago > last_check_in
    one.push(node)
  end
  puts node['name'] + " has checked in within the last hour"
end
puts "-------------------------------------------------------------"

one.each {|n| puts "One hour: #{n['name']}" }
two.each {|n| puts "Two hours: #{n['name']}" }
alert.each {|n| puts "Alert: #{n['name']}" }
amber.each {|n| puts "Amber: #{n['name']}" }
red.each {|n| puts "Red: #{n['name']}" }
