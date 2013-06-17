# ChangeLog

## NEXT

  *

## v2.1.3 (2013-06-17)

  * Uses newest version of engineyard-serverside 2.1.4
    * Doesn't reuse assets when assets were not compiled last deployment.
    * Improves composer support.
  * Supports new flag `--shell (-s)` for `ey ssh` which allows you to choose the shell that runs the command. (default: bash) Has no effect on `ey ssh` without a command.
  * Supports new flag `--no-shell` to run the `ey ssh` command without a shell. (this is the standard behavior of the unix ssh command) Has no effect on `ey ssh` without a command.

## v2.1.2 (2013-06-05)

  * Uses newest version of engineyard-serverside 2.1.3
    * Fixes a formatting error in sqlite database.yml files.
    * Patches LANG gem install error.

## v2.1.1 (2013-05-30)

  * Use newest deployment version that patches a problem with calling Set#first on some ruby versions.

## v2.1.0 (2013-05-28)

  * Add a new command `ey timeout-deploy` which will mark stuck deploys as canceled.
  * Bumps default bundler version to latest 1.3.4
  * During deploy, doesn't precompile assets when git-diff shows no changes to `asset_dependencies`
  * Supports new ey.yml option `asset_dependencies` which is a list of relative paths to search for asset changes each deploy.
    * The default `asset_dependencies` are: app/assets lib/assets vendor/assets Gemfile.lock config/routes.rb
  * Supports new ey.yml option `precompile_unchanged_assets: true` compiles assets even if no changes would be detected.
  * Supports new ey.yml option `precompile_assets_task: taskname` which overrides the default `assets:precompile`
  * Supports new ey.yml option `asset_strategy` which supports: `shared`, `private`, `cleaning`, or `shifting`.
    * The default asset strategy is `shifting` which is the same behavior as previous versions.
    * See `README.markdown` or [`lib/engineyard-serverside/rails_assets/strategy.rb`](https://github.com/engineyard/engineyard-serverside/blob/master/lib/engineyard-serverside/rails_assets/strategy.rb) for full explanation.
  * Supports new ey.yml option `bundle_options` which can be used to specify additional bundle install command line options.
  * Supports setting of ey.yml option `bundle_without` to nil to remove `--without` from the bundle install command.
  * Refactor dependency management (bundler, npm, none) to allow more flexibility (may break existing eydeploy.rb files)
  * Supports new ey.yml option `eydeploy_rb: false` which enables or disables eydeploy.rb file loading. (default: load eydeploy.rb)
  * Changes the order of eydeploy.rb loading to happen after ey.yml is parsed during deploy.
  * Fixes a race condition during deploy where `current` symlink was not moved atomically.

## v2.0.12 (2013-04-11)

  * Uses new version of engineyard-serverside 2.0.6 with the following bug fixes:
    * Fix for command line config option `--config precompile_assets:true/false` which was being interpreted as a string.
    * Don't exclude the `RAILS_ENV` Gemfile group from bundle install. (i.e. don't do `--without development` in `development` mode)

## v2.0.11 (2013-02-12)

  * New version of `engineyard-serverside` which includes:
    * Change concurrency code to use a simple threaded model (faster deploys on some instances)
    * Clean up local branches that might interfere with the git checkout.

## v2.0.10 (2012-12-17)

  * Command line option -q (or --quiet) mutes non-essential CLI output for most commands.
  * Uses new version 2.0.4 of the deploy system.
  * Supports new ey.yml option during deploy to control on which roles asset precompilation happens.
    * Follows YAML Array syntax (using :app, :app\_master, :solo, :util) or :all.
    * Syntax: `asset_roles: :all (default is to exclude :util but include all others. [:app, :app_master, :solo])`
  * During deploy, adds `RAILS_GROUPS=assets` to rake assets:precompile to improve asset compilation performance.
  * Records exceptions raised during deploy into the deploy log when possible.
  * Fixes a bug where permissions problems may cause integrate action to fail.
  * Fixes a problem where "maintenance page still up" notice would stay on Cloud Dashboard too long. Downgraded message severity.
  * Garbage collect git at the end of each deploy. First one may take a while but the next ones will be faster and reduce extra disk usage.

## v2.0.9 (2012-10-29)

  * Send serverside version to the deploy API to help with 2.0.x upgrade path on dashboard.
  * Upgrade to engineyard-cloud-client version 1.0.7

## v2.0.8 (2012-10-23)

  * Vendor Thor to help reduce Rails incompatibilities.

## v2.0.7 (2012-09-24)

  * During deploy, --config can be used to override most ey.yml options on demand.
  * Alias --extra-deploy-hook-options as --config for easier usage.

## v2.0.6 (2012-09-19)

  * During deploy, only symlink shared config files that actually exist.
  * During deploy, don't display the database adapter warning when the environment does not have a database.
  * During deploy, chown shared/bundled\_gems dir to deploy user to ensure bundle install works.

## v2.0.5 (2012-09-05)

  * Fix calls to system() leaking stdout into the command output.

## v2.0.4 (2012-09-05)

  * Don't redirect command output to /dev/null because windows doesn't like it.

## v2.0.3 (2012-08-29)

  * Use new serverside-adapter that allows setting engineyard-serverside version separately.

## v2.0.2 (2012-08-24)

  *

## v2.0.1 (2012-08-21)

  * Update serverside to print less deprecation warnings.

## v2.0.0 (2012-08-16)

  * Repository interactions pay attention to $GIT\_DIR and $GIT\_WORK\_TREE.
  * Increases responsiveness of most API interactions.
  * Prints notices when ey.yml defaults are used.
  * Improves failed deployment output messaging.
  * Allows `--app`, `--account`, and `--environment` for `ey environments` for extra filtering.
  * Prints an error when a command line option, like `--environment`, is specified without an argument.
  * No longer guesses migration behavior. ey.yml must contain `migrate: true # or false` for each environment. ey deploy will walk you through on your first deploy.
  * Adds command `ey web restart` to restart application servers without deploying.
  * New version of `engineyard-serverside` (and adapter), which includes:
    * Default bundler version is now 1.1.5.
    * Deploy hooks now have access to `account_name` and `environment_name`.
    * Improves deploy output, especially for `--verbose`.
    * Sends all log output through a new Shell object that formats and adds timestamps.
    * Loads `ey.yml` or `config/ey.yml` to customize deploy settings.
    * Supports new ey.yml options to control automatic maintenance page:
      * `maintenance_on_restart: true or false (default: false except for glassfish and mongrel)`
      * `maintenance_on_migrate: true or false (default: true)`
    * Don't remove maintenance pages that weren't put up during this deploy if maintenance options (above) are set to false.
    * Supports new ey.yml options to control asset precompilation:
      * `precompile_assets: true or false (default: inferred using app/assets and config/application.rb)`
    * Supports new ey.yml option to ignore the missing database adapter warning:
      * `ignore_database_adapter_warning: true (default: false)`
    * Fixes a bug that could cause Passenger to restart multiple times during each deploy.
    * Change order of compile\_assets during deploy. Compile assets now happens before enabling maintenance page.

## v1.4.28 (2012-03-29)

  *

## v1.4.27 (2012-03-22)

  *

## v1.4.26 (2012-03-22)

  *

## v1.4.25 (2012-03-21)

  *

## v1.4.24 (2012-03-19)

  *

## v1.4.23 (2012-02-29)

  *

## v1.4.22 (2012-01-27)

  *

## v1.4.21 (2012-01-19)

  * ey logout removes the API token from ~/.eyrc
  * ey login logs you in (don't be surprised)

## v1.4.20 (2012-01-13)

  *

## v1.4.19 (2012-01-12)

  * Failed releases are now saved in a 'releases\_failed' directory, parallel to the existing 'releases' directory.
  * Resolved a bundler version conflict that could occur for apps that specified a particular bundler version.

## v1.4.18 (2012-01-03)

  * Previous release had gemspec problems (seriously rubygems, releasing from 1.9.3 shouldn't break everyone on 1.8)

## v1.4.17 (2011-12-28)

  * Force encoding on commands going across Net::SSH (which seems incapable of handling UTF-8 encoded strings)
  * Diagnostic code for command encoding when running in verbose mode.

## v1.4.16 (2011-12-21)

  * Upgrade to latest net-ssh to fix string encoding issues in 1.9.x.

## v1.4.15 (2011-12-14)

  * Add support for $ENGINEYARD\_API\_TOKEN on the command line to override token fetching.
  * Fix lingering AppCloud mentions.
  * Use -R [REF] or --force-ref [REF] to override the default branch. Specifying --ignore-default-branch, --force-ref or -R without arguments still works like before.

## v1.4.14 (2011-12-13)

  * Put more information in the deploy logs so failing deploys show something.
  * Expose deployed\_by user name in deploy hooks.
  * Handle not found when accessing deployment api before deploying.

## v1.4.13 (2011-12-07)

  * Fix last release.

## v1.4.12 (2011-12-07)

  * Print more informative messages on deploy.
  * Include new version of deploy system that fixes a bug with GIT\_SSH not being set for some instances.

## v1.4.11 (2011-11-29)

  * Fix gemspec problem

## v1.4.10 (2011-11-26)

  *

## v1.4.9 (2011-11-26)

  * Includes an engineyard-serverside fix to prevent rebuilding gems on every deploy.

## v1.4.8 (2011-11-22)

  * The below changes improve other-ruby support. Notably, engineyard should now work from rubinius for the most part.
  * [refactor] More require, less autoload
  * [refactor] Clean up the way we read and write the .eyrc file.
  * [internal] Specs no longer depend on FakeFS.
  * [internal] Remove unused 'custom endpoint' complexity. $CLOUD\_URL can still be set to override the api endpoint.

## v1.4.7 (2011-11-16)

  * Exit from ey ssh with the exit status of the ssh command. If running on multiple instances, exits with the status of the first failure, or 0 if all instances succeed.
  * Set LANG to 'en\_US.UTF-8' while installing gems to avoid failures on 1.9.x

## v1.4.6 (2011-11-10)

  * Ran into the YAML Syck thing again when building the last version. Re-releasing.

## v1.4.5 (2011-11-10)

  * Use new engineyard-serverside version that should actually really fix the 32bit / 64bit problem. We now check every instance instead of (incorrectly) only checking the app master.

## v1.4.4 (2011-11-07)

  *

## v1.4.3 (2011-11-01)

  * Include new engineyard-serverside version with fixes:
  * Deploy fix: Don't fail if we can't precompile assets.
  * Deploy fix: Delete bundled\_gems directory if we can't determine under which 32 or 64bit the last bundle was run.

## v1.4.2 (2011-10-21)

  * bundle\_without: ey.yml option allows you to specify custom bundle install --without string (list of space separated groups, replaces the default 'test development') Put the option in your ey.yml file under the environment name key.
  * Includes a fix for Gemfile detection in engineyard-serverside.

## v1.4.1 (2011-10-18)

  * Improve warning messages during deploys.
  * Exclude bundler environment variables explicitly on bundler install during deploy.

## v1.4.0 (2011-10-07)

  * Remove bundler 0.9 support in engineyard-serverside.
  * `ey whoami` will tell you who you're logged in as.

## v1.3.33 (2011-09-27)

  *

## v1.3.32 (2011-09-23)

  * Use the environments API to check whether run migrations or not when the flag is
    not provided.

## v1.3.31 (2011-09-21)

  *

## v1.3.30 (2011-09-19)

  *

## v1.3.29 (2011-09-15)

  *

## v1.3.27 (2011-09-14)

  *

## v1.3.26 (2011-09-13)

  *

## v1.3.25 (2011-09-12)

  *

## v1.3.24 (2011-09-11)

  *

## v1.3.23 (2011-09-08)

  * Update version of serverside gem for rails 3.1 assets support.

## v1.3.22 (2011-08-09)

  * Patch RestClient to stop sending cookies - they interfere with AWS S3.

## v1.3.21 (2011-08-03)

  * Update README to include more info about the ey.yml config.
  * Suggest ey environments --all when no environments match.
  * Fix an issue with uploading recipe tgz files on windows.

## v1.3.20 (2011-05-27)

  * Start recording the new load_balance_ip_address from the environment API.
  * Fix for deprecated API key "stack_name"

## v1.3.19 (2011-05-23)

  * `ey status` shows most recent deployment status of an app and environment.

## v1.3.18 (2011-05-08)

  * Add --file (-f) option to specify a .tgz file containing the custom cookbooks dirctory.
  * Add --apply option which automatically runs recipes uploaded with `ey recipes upload`.
  * Improve recipes documentation.
  * Alias ey update to ey rebuild to conform to the terminology on the AppCloud dashboard.
  * Improve the documentation in the README file.
  * Send a User-Agent header with all API requests.

## Begin ChangeLog (2011-05-05)
