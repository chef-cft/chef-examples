automat_dir = '/hab/pkgs/chef/automate-ui/2.0.0'
unless ::File.directory?(automat_dir)
  raise "Directory #{automat_dir} is missing!"
end
files = ::Dir.glob(::File.join(automat_dir, '*'))
parent_dir = ::File.basename(files.first) # => '20240305055235'
 
 
file_names_tobe_deleted = %w(collection chef)
 
 
file_names_tobe_deleted.each do |f|
  file_to_be_deleted = "#{automat_dir}/#{parent_dir}/dist/assets/chef-ui-library/#{f}/sandbox.html"
  file file_to_be_deleted do
    action :delete
  end
end
file_to_be_created = '/home/tag-file'
file file_to_be_created do
  action :create
end
