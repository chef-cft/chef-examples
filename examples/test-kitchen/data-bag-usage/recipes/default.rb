#
# Cookbook:: data-bag-usage
# Recipe:: default
#
# Copyright:: 2021, Chef Customer-Facing Teams, All Rights Reserved.

# Read a data_bag and items from an alternate specified location in the kitchen yml
if node['kitchen_suite_action'] == 'alt-data-bag-location'
  data_bag = data_bag('alt1')
  data_bag_item = data_bag_item('alt1', 'item1')
else
  # Look for a data bag in the default Test Kitchen location and read the contents
  data_bag = data_bag('default')
  data_bag_item = data_bag_item('default', 'item1')
end

# Use the contents of the data_bag item which was loaded for resources in the recipe.
log "Reading from data_bag: #{data_bag}"

data_bag_item.each do |_key, value|
  file "/tmp/#{value}"
end
