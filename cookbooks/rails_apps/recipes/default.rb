require_recipe "passenger"

directory "/data/apps" do
  action :create
  owner node[:user]
  group node[:user]
  mode 0775
end

directory "/data/logs" do
  action :create
  mode 0755
  owner node[:user]
  group node[:user]
end

directory "/data/logs/apps" do
  action :create
  mode 0775
  owner node[:user]
  group "www-data"
end

node[:applications].each do |app|
  
  app[:user] ||= node[:user]
  app[:group] ||= app[:user]
  app[:env] ||= 'production'
  
  app_dir = "/data/apps/#{app[:name]}"
  
  full_name = "#{app[:name]}_#{app[:env]}"
  
  directory app_dir do
    owner app[:user]
    group app[:group]
    mode 0755
    action :create
    recursive true
  end

  directory "#{app_dir}/shared" do
    owner app[:user]
    group app[:group]
    mode 0755
    action :create
    recursive true
  end

  directory "#{app_dir}/shared/config/" do
    owner app[:user]
    group app[:group]
    mode 0755
    action :create
  end
  
  # config apache
  passenger_app app[:name] do
    env app[:env]
    server_name app[:server_name]
    server_alias app[:server_alias]
  end

  # setup logrotate
  # logrotate full_name do
  #   files "/data/apps/#{app[:name]}/current/log/*.log"
  #   frequency "weekly"
  #   restart_command "/etc/init.d/apache2 reload > /dev/null"
  # end
  
  # setup mysql
  db_user_attrs = {:user => app[:user], 
                   :password => app[:mysql_password], 
                   :database => "#{app[:name]}_#{app[:env]}"}
  
  template "#{app_dir}/shared/config/database.yml" do
    owner app[:user]
    group app[:group]
    mode 0655
    source "database.yml.erb"
    #enable true
    variables(db_user_attrs)
    action :create_if_missing
  end
  
  # Create empty db
  template "/tmp/empty-#{app[:name]}-db.sql" do
    owner 'root'
    group 'root'
    mode 0644
    source "empty-db.sql.erb"
    variables(db_user_attrs)
  end
  
  execute "create-empty-db-for-#{app[:name]}" do
    command "mysql -u root -p'#{node[:mysql_root_pass]}' < /tmp/empty-#{app[:name]}-db.sql"
  end
  
  # install gems
  if app[:gems]
    app[:gems].each do |g|
      if g.is_a? Array
        gem_package g.first do
          version g.last
        end
      else
        gem_package g
      end
    end
  end
  
  # install packages
  if app[:packages]
    app[:packages].each do |package_name|
      package package_name
    end      
  end
  
  # setup required symlinks
  if app[:symlinks]
    app[:symlinks].each do |target, source|
      link target do
        to source
      end
    end
  end

  # install apache modules
  if app[:apache_modules]
    app[:apache_modules].each do |mod|
      apache_module mod
    end
  end
  
end