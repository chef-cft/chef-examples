current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
client_key              "#{current_dir}/souschef.user.key"
chef_server_url          'https://server.bootstrap/organizations/bootstrap'
cache_type               'BasicFile'
cache_options( :path => "#{ENV['HOME']}/.chef/checksums" )
cookbook_path            ["#{current_dir}/../cookbooks"]
