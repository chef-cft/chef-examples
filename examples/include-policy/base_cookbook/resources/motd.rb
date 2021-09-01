# To learn more about Custom Resources, see https://docs.chef.io/custom_resources/

unified_mode true

property :motd_content, String, default: "Hello this is the message of the day. Thanks for watching.\n"

action :create do
  file '/etc/motd' do
    content new_resource.motd_content
  end
end
