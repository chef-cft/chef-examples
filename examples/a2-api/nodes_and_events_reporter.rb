#!/usr/bin/env ruby
require 'net/http'
require 'JSON'
require 'fileutils'
require 'mail'
require 'optparse'
require 'Time'

 ######################################################################################################################################################
# TODO: Emailer - Coming in V2
# TODO: Finish SSL verify portion to accept certs into code.

 ####################################################################### README ##########################################################################
# To use the reporting tool, you must do the following:
# Select the report type, node or event.
# Automate URL and Token can be given at the commandline or set as ENV Variables
# Then the output name.
# Nodes_and_Events.rb -h for Additional Options

 ####################################################################### EXAMPLES  #######################################################################
# Prints All Nodes

# PRINTS MISSING NODES
# /nodes_and_events_reporter.rb -r node -o report.txt --url URL --token TOKEN --status missing

# Prints ALL EVENTS
# ./nodes_and_events_reporter.rb -r event -o report.txt --url URL --token TOKEN

# Prints Client Events
# /nodes_and_events_reporter.rb -r event -o report.txt --url URL --token TOKEN   --type client

# Prints Client Events At Specific Time
# ./nodes_and_events_reporter.rb -r event -o report.txt --type client --start_date 2020-09-19'T'12:00:00Z
######################################################################################################################################################
######################################################################################################################################################

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"

  opts.on('-oFILENAME', '--output=FILENAME', 'Filename for report output.') do |output|
    unless output
      puts 'You must provide a filename for report output.'
      puts
      puts opts
      exit 1
    end
    options[:output] = output
  end

  opts.on('-rREPORT', '--report=REPORT', 'What type of report to run: node, event') do |r|
    unless %w(node event).include?(r)
      puts 'Only the following report types are recognized: node, event'
      puts ''
      puts opts
      exit 1
    end
    options[:report] = r
  end

  opts.on('--url=url', 'Automate URL, i.e. https://AUTOMATE_URL') do |url|
    options[:automate_url] = url
  end

  opts.on('--token=token', 'Automate Admin Token') do |token|
    options[:api_token] = token
  end


  opts.on('--status=status', 'Filter node report by status') do |status|
    options[:status_filter] = status
  end

  opts.on('--type=type', 'Filter event report by type') do |type|
    options[:type_filter] = type
  end

  opts.on('--task=task', 'Filter event report by task') do |task|
    options[:task_filter] = task
  end

  opts.on('-s', '--start_date=start_date', 'Starting date the data should filter. (Optional (2020-07-19\'T\'12:00:00Z))') do |start|
    options[:start_date] = start
  end

  opts.on('-e', '--end_date=end_date', 'Ending date the data should filter.(Optional (2020-07-19\'T\'12:00:00Z))') do |ending|
    options[:end_date] = ending
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

class Reporter
  attr_reader :reportfilename, :automate_url, :api_token, :receiver, :sender, :report_type

  def initialize(options)
    @reportfilename = options[:output] || raise('You must provide a report output filename.')
    @automate_url = options[:automate_url] || ENV['AUTOMATE_URL']
    @api_token = options[:api_token] || ENV['AUTOMATE_TOKEN']
    @sender = options[:sender]
    @report_type = options[:report]
  end

  def api_req
    raise NotImplementedError, 'This is an abstract class. You must define this method in a child reporter.'
  end

  def process_data
    raise NotImplementedError, 'This is an abstract class. You must define this method in a child reporter.'
  end

  def report_header
    raise NotImplementedError, 'This is an abstract class. You must define this method in a child reporter.'
  end

  def get_data
    verify_with_ssl = false
    url = URI(automate_url + api_req)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    if verify_with_ssl == true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.ca_file = cert_home
    elsif verify_with_ssl == false
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    request = Net::HTTP::Post.new(url)
    request['api-token'] = api_token

    request.body = JSON.dump('filters' => [])
    response = http.request(request)

    case response
    when Net::HTTPSuccess, Net::HTTPRedirection
      JSON.parse(response.body)
    else
      puts 'Attempted to request:'
      puts request.inspect
      puts 'Received in response:'
      puts response.inspect
      raise 'API call failed. Unable to report.'
    end
  end

  def write_report
    open(reportfilename, 'w') do |file|
      file.write(report_header)
      file.write(process_data.join("\n"))
    end
  end

end

class NodeReporter < Reporter
  attr_reader :status_filter, :start_date, :end_date

  def initialize(options)
    super(options)
    @status_filter = options[:status_filter]
    @start_date = options[:start_date]
    @end_date = options[:end_date]
  end

  def api_req
    api = '/api/v0/cfgmgmt/nodes?pagination.page=1&pagination.size=100&sorting.field=name&sorting.order=ASC'

    if status_filter
      api += "&filter=status:#{status_filter}"
    end

    if start_date
      api += "&start=#{start_date}"
    end

    if end_date
      api += "&end=#{end_date}"
    end
    api
  end

  def process_data
    nodes = get_data
    nodes.map do |node|
      <<~OUTPUT
        Hostname: #{node['hostname']}
        Environment: #{node['environment']}
        Platform: #{node['platform']}
        Check-In Time: #{node['checkin']}
        Current Status: #{node['status']}
      OUTPUT
    end
  end

  def report_header
    time = Time.new
    "#{status_filter} Node Report for #{time.strftime('%m/%d/%Y')}\n\n"
  end
end

class EventReporter < Reporter
  attr_reader :type_filter, :task_filter, :start_date, :end_date

  def initialize(options)
    super(options)
    @type_filter = options[:type_filter]
    @task_filter = options[:task_filter]
    @start_date = options[:start_date]
    @end_date = options[:end_date]
  end

  def api_req
    api = '/api/v0/eventfeed?collapse=true&page_size=1000'

    if task_filter
      api += "&filter=task:#{task_filter}"
    end

    if start_date
      parse = start_date.split('-')
      year = parse[0]

      month = if parse[1].include?('0')
                parse[1].split('0')[1]
              else
                parse[1]
              end

      day = parse[2].split('T')[0]
      hour = parse[2].split('T')[1].split(':')[0]
      min = parse[2].split('T')[1].split(':')[1]
      sec = parse[2].split('T')[1].split(':')[2].chomp('Z')

      start_integer = Time.new(year, month, day, hour, min, sec).strftime('%s%3N')

      api += "&start=#{start_integer}"
    end
    if end_date

      parse = end_date.split('-')
      year = parse[0]

      month = if parse[1].include?('0')
                parse[1].split('0')[1]
              else
                parse[1]
              end

      hour = parse[2].split('T')[1].split(':')[0]
      min = parse[2].split('T')[1].split(':')[1]
      sec = parse[2].split('T')[1].split(':')[2].chomp('Z')

      end_integer = Time.new(year, month, day, hour, min, sec).strftime('%s%3N')

      api += "&end=#{end_integer}"
    end
    api
  end

  def process_data
    events = get_data['events']

    if type_filter
      events = events.select { |event| event['event_type'] == type_filter }
    end

    events.map do |event|
      <<~OUTPUT
              Event Type: #{event['event_type']}
              Entity Name: #{event['entity_name']}
              Task Performed: #{event['task']}
              Start Time: #{event['start_time']}
              End Time: #{event['end_time']}
              Requestor Type: #{event['requestor_type']}
              Requestor Name: #{event['requestor_name']}
              Parent Name: #{event['parent_name']}
            OUTPUT
    end
  end

  def report_header
    time = Time.new
    "#{type_filter} Events Report for #{time.strftime('%m/%d/%Y')}\n\n"
  end
end

case options[:report]
when 'node'
  NodeReporter.new(options).write_report
when 'event'
  EventReporter.new(options).write_report
else
  puts 'Please select a report type: node, event'
end

