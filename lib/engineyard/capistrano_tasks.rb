# seamusabshere 10/11/10 this is not extremely fast
task :engineyard_roles do
  if app_master = `ey metadata app_master --environment #{engineyard_environment}` and app_master.strip.length > 0
    role :app_master, app_master
  end
  if db_master = `ey metadata db_master --environment #{engineyard_environment}` and db_master.strip.length > 0
    role :db_master, db_master
  end
  if solo = `ey metadata solo --environment #{engineyard_environment}` and solo.strip.length > 0
    role :solo, solo
  end
  `ey metadata utilities --environment #{engineyard_environment}`.split(',').select{ |i| i.strip.length > 0 }.each do |i|
    role :util, i
  end
  `ey metadata app_servers --environment #{engineyard_environment}`.split(',').select{ |i| i.strip.length > 0 }.each do |i|
    role :app, i
    role :web, i
    role(:app_slave, i) unless i == app_master or i == solo
  end
  `ey metadata db_servers --environment #{engineyard_environment}`.split(',').select{ |i| i.strip.length > 0 }.each do |i|
    role :db, i
    role(:db_slave, i) unless i == app_master or i == solo
  end
end
