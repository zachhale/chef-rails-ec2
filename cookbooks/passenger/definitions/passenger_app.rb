define :passenger_app do
  root = "/data/apps/#{params[:name]}/current"
  docroot = root + "/public"
  full_name = "#{params[:name]}_#{params[:env]}"
  
  template "/etc/apache2/sites-available/#{full_name}" do
    owner 'root'
    group 'root'
    mode 0644
    source "passenger.vhost.erb"
    variables({
      :name => full_name,
      :docroot  => docroot,
      :server_name  => params[:server_name],
      :server_alias => params[:server_alias],
      :max_pool_size  => params[:max_pool_size] || 4,
      :ssl => params[:ssl],
      :env => params[:env]
    })
    # only_if { File.exists?(docroot) }
  end

  #link "#{root}/config/apache/#{params[:env]}.conf" do
  #  to "/etc/apache2/sites-available/#{full_name}"
  #end
  
  #enable_setting = params[:enable]
  
  apache_site full_name do
    enable true
    only_if { File.exists?("/etc/apache2/sites-available/#{full_name}") }
  end
end