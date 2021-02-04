#
# Cookbook:: data-bag-usage
# Spec:: default
#
# Copyright:: 2021, Chef Customer-Facing Teams, All Rights Reserved.

require 'spec_helper'

describe 'data-bag-usage::default' do
  context 'When kitchen_suite_action is default' do
    platform 'ubuntu', '20.04'

    before do
      stub_data_bag('default').and_return({})
      stub_data_bag_item('default', 'item1').and_return({})
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end
  end

  context 'When kitchen_suite_action is alt-data-bag-location' do
    platform 'ubuntu', '20.04'
    default_attributes['kitchen_suite_action'] = 'alt-data-bag-location'

    before do
      stub_data_bag('alt1').and_return({})
      stub_data_bag_item('alt1', 'item1').and_return({})
    end

    it 'converges successfully' do
      expect { chef_run }.to_not raise_error
    end
  end
end
