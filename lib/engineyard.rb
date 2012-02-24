thor_lib = File.expand_path(File.join(File.dirname(__FILE__), 'vendor', 'thor', 'lib'))
$:.unshift thor_lib
require 'engineyard-cloud-client'

module EY
  require 'engineyard/version'
  require 'engineyard/error'
  require 'engineyard/config'

  autoload :Repo,       'engineyard/repo'
end
