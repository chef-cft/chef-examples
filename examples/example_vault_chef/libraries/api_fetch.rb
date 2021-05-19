#
# Chef Infra Documentation
# https://docs.chef.io/libraries/
#

#
# This module name was auto-generated from the cookbook name. This name is a
# single word that starts with a capital letter and then continues to use
# camel-casing throughout the remainder of the name.
#
module ExampleVaultChef
  module ApiFetchHelpers
    def api_json_fetch(path)
      # Should not be needed to require net/http within Chef Infra client run, but being paranoid.
      require 'net/http'
      url = URI(path)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true if http.port.to_s =~ /443/
      req = http.get(url)
      JSON.parse(req.body)
      # rescue => err
      #   puts
      #   puts "There was an error sending GET to #{path}"
      #   puts err
    end
  end
end

Chef::DSL::Universal.include ::ExampleVaultChef::ApiFetchHelpers
