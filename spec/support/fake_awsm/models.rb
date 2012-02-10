require File.expand_path('../models/account', __FILE__)
require File.expand_path('../models/app', __FILE__)
require File.expand_path('../models/app_environment', __FILE__)
require File.expand_path('../models/environment', __FILE__)
require File.expand_path('../models/user', __FILE__)
require File.expand_path('../models/instance', __FILE__)

require 'dm-migrations'
require 'dm-aggregates'
DataMapper.setup(:default, "sqlite::memory:")
DataMapper.finalize
DataMapper.auto_migrate!
