# `ey` engineyard Command Line Interface

[![Gem Version](https://badge.fury.io/rb/engineyard.png)][gem]
[![Build Status](https://travis-ci.org/engineyard/engineyard.png?branch=master)][travis]
[![Dependency Status](https://gemnasium.com/engineyard/engineyard.png?travis)][gemnasium]
[![Code Climate](https://codeclimate.com/github/engineyard/engineyard.png)][codeclimate]

[gem]: https://rubygems.org/gems/engineyard
[travis]: https://travis-ci.org/engineyard/engineyard
[gemnasium]: https://gemnasium.com/engineyard/engineyard
[codeclimate]: https://codeclimate.com/github/engineyard/engineyard

The Engine Yard command line utility.

### Installing on Ruby 1.8.7 or 1.9.2

**NOTE: This has *no effect* on your Engine Yard environment ruby version. This
is only regarding the local development Ruby version for running this gem. An
environment can continue using a chosen Ruby version regardless of this change.**

This gem now wraps the [ey-core](https://github.com/engineyard/core-client-rb) gem by default.
If you wish to access the old gem behavior, call the binary as `ey legacy` and then append
the rest of the command as normal.  This legacy behavior will be phased out over time.

### Install

Install engineyard like any other ruby gem:

    gem install engineyard

Note: Don't add engineyard to your application's Gemfile. The engineyard gem is
not made to be a part of your application and may cause version conflicts with
other parts of rails.

### Login

The first command you run will notice that you are not logged in and will ask
you for your Engine Yard email and password.

### Configuration

The `ey.yml` file allows options to be saved for each environment to which an
application is deployed.

A typical Rails application will have a `config/ey.yml` like this:

    ---
    # This is all you need for a typical rails application.
    defaults:
      migrate: true
      migration_command: rake db:migrate
      precompile_assets: true

The following `ey.yml` file shows other things that can be customized.
A typical application will not need most of these options.

    ---
    # 'defaults' applies to all environments running this application.
    # Only set these options if needed. The defaults are correct for most applications.
    defaults:
      bundler: detect                           # By default, bundler is detected via Gemfile. Options: true: always run bundler; false: never run bundler
      composer: detect                          # By default, composer is detected via composer.lock. Options: true: always run composer; false: never run composer
      npm: detect                               # By default, npm is detected via package.json. Options: true: always run npm; false: never run npm
      bundle_without: GROUP1 GROUP2             # exclude groups on bundle install (default: test development)
      bundle_options: --OPTION                  # extra bundle install options (--local, --quiet, etc; does not override bundle_without)
      copy_exclude:                             # don't rsync the following dirs (some people like to skip .git)
      - SOME_LARGE_DIR
      keep_releases: 3                          # number of releases to keep in /data/APP_NAME/releases. Older releases are removed. Default: 3
      maintenance_on_restart: false             # show maintenance page during app restart (default: false except for glassfish and mongrel)
      maintenance_on_migrate: true              # show maintenance page during migrations (default: true)
      precompile_assets: true                   # enables rails assets precompilation (default: inferred using app/assets and config/application.rb)
      precomplie_assets_task: assets:precompile # override the assets:precompile rake task
      precompile_unchanged_assets: false        # if true, does not check git for changes before precompiling assets.
      asset_dependencies:                       # a list of relative paths to search for asset changes during each deploy.
      - app/assets                              # default
      - lib/assets                              # default
      - vendor/assets                           # default
      - Gemfile.lock                            # default
      - config/routes.rb                        # default
      - config/application.rb                   # default
      - config/requirejs.yml                    # custom option (be sure to include defaults if you specify this option)
      asset_strategy: shifting                  # choose an alternet asset management strategy. See rails_assets/strategy.rb for more info.
      asset_roles: :all                         # specify on which roles to compile assets (default: [:app, :app_master, :solo])
      ignore_database_adapter_warning: true     # hide database adapter warning if you don't use MySQL or PostgreSQL (default: false)

    # Environment specific options apply only to a single environment and override settings in defaults.
    environments:
      env_production:
        precompile_unchanged_assets: true       # precompiles assets even if no changes would be detected (does not check for changes at all).
        asset_strategy: shifting                # choose an alternet asset management strategy (shifting, cleaning, private, shared)
        asset_roles: :all                       # specify on which roles to compile assets (default: [:app, :app_master, :solo] - must be an Array)
      env_staging
        asset_strategy: private                 # Use an asset management that always refreshes, so staging enviroments don't get conflicts

These options in `ey.yml` will only work if the file is committed to your
application repository. Make sure to commit this file. Different branches
may also have different versions of this file if necessary. The ey.yml file
found in the deploying commit will be used for the current deploy.


### Commands

#### ey init

Initialize a repository for deployment on Engine Yard Cloud.

This command writes or updates an ey.yml file which explains options available
for customizing the deployment process.

`ey init` can be run in existing applications to update the ey.yml file
without losing existing settings.

NOTE: Please verify all settings and changes after running ey init for
the first time.

#### ey deploy

This command must be run within the current directory containing the app to be
deployed. If ey.yml specifies a default branch then the ref parameter can be
omitted. Furthermore, if a default branch is specified but a different
command is supplied the deploy will fail unless `--ignore-default-branch`
is used.

If ey.yml does not specify a default migrate choice, you will be prompted to
specify a migration choice. A different command can later be specified via
`--migrate "ruby do_migrations.rb"`. Migrations can also be skipped entirely
by using --no-migrate.

Options:

    -r, [--ref=REF] [--branch=] [--tag=]      # Git ref to deploy. May be a branch, a tag, or a SHA.
    -c, [--account=ACCOUNT]                   # Name of the account in which the environment can be found
    -a, [--app=APP]                           # Name of the application to deploy
    -e, [--environment=ENVIRONMENT]           # Environment in which to deploy this application
    -m, [--migrate=MIGRATE]                   # Run migrations via [MIGRATE]; use --no-migrate to avoid running migrations
    -v, [--verbose]                           # Be verbose
        [--ignore-default-branch]             # Force a deploy of the specified branch even if a default is set
        [--ignore-bad-master]                 # Force a deploy even if the master is in a bad state
        [--extra-deploy-hook-options key:val] # Additional options to be made available in deploy hooks (in the 'config' hash)
                                              # Add more keys as follows: --extra-deploy-hook-options key1:val1 key2:val2

#### ey timeout-deploy

The latest running deployment will be marked as failed, allowing a
new deployment to be run. It is possible to mark a potentially successful
deployment as failed. Only run this when a deployment is known to be
wrongly unfinished/stuck and when further deployments are blocked.

NOTICE: This command is will indiscriminately timeout any deploy, with no
regard for its potential success or failure. Confirm that the running
deploy is actually stuck or broken before running this command. If run
against a deploy that would succeed, it could cause the deployment to be
marked as failed incorrectly.

Options:

    -c, [--account=ACCOUNT]                   # Name of the account in which the environment can be found
    -a, [--app=APP]                           # Name of the application containing the environment
    -e, [--environment=ENVIRONMENT]           # Name of the environment with the desired deployment


#### ey status

Show the status of most recent deployment of the specified application and
environment. This action only informational and will not change your application.

Options:

    -c, [--account=ACCOUNT]                   # Name of the account in which the environment can be found
    -a, [--app=APP]                           # Name of the application containing the environment
    -e, [--environment=ENVIRONMENT]           # Name of the environment with the desired deployment

#### ey environments

By default, environments for this app are displayed. The `--all` option will
display all environments, including those for this app.

Options:

    -c, [--account=ACCOUNT]                   # Name of the account in which the environment can be found
    -a, [--app=APP]                           # Name of the application containing the environments
    -e, [--environment=ENVIRONMENT]           # Show only environments matching named environment
    -s, [--simple]                            # Print each environment name on its own on a new line
    -a, [--all]                               # Show all environments, not just ones associated with this application.

#### ey servers

List all servers on an environment.

Options:

    -c, [--account=ACCOUNT]                   # Name of the account in which the environment can be found
    -e, [--environment=ENVIRONMENT]           # Show only servers in the named environment
    -u, [--user]                              # Print the user@ in front of the server hostname to make ssh connections simpler
    -s, [--simple]                            # Print each server on a new line with hostname, role, and name separated by tabs
    -S, [--host]                              # Print each server on a new line with hostname only. Use -Su for 'user@host'

Example output:

    $ ey servers -s
    ec2-10-0-0-0.us-west-2.compute.amazonaws.com	i-aabbccdd	app_master
    ec2-10-0-0-1.us-west-2.compute.amazonaws.com	i-bbccddee	app
    ec2-10-0-0-2.us-west-2.compute.amazonaws.com	i-ccddeeff	db_master
    ec2-10-0-0-3.us-west-2.compute.amazonaws.com	i-ddeeffaa	util	resque

    $ ey servers -Su
    deploy@ec2-10-0-0-0.us-west-2.compute.amazonaws.com
    deploy@ec2-10-0-0-1.us-west-2.compute.amazonaws.com
    deploy@ec2-10-0-0-2.us-west-2.compute.amazonaws.com
    deploy@ec2-10-0-0-3.us-west-2.compute.amazonaws.com


#### ey logs

Displays Engine Yard configuration logs for all servers in the environment. If
recipes were uploaded to the environment and run, their logs will also be
displayed beneath the main configuration logs.

Options:

    -e, [--environment=ENVIRONMENT]  # Environment with the interesting logs
    -c, [--account=ACCOUNT]          # Name of the account in which the environment can be found

#### ey rebuild

Engine Yard's main configuration run occurs on all servers. Mainly used to fix
failed configuration of new or existing servers, or to update servers to latest
Engine Yard stack (e.g. to apply an Engine Yard supplied security patch).

Note that uploaded recipes are also run after the main configuration run has
successfully completed.

This command will return immediately, but the rebuild process may take a few
minutes to complete.

Options:

    -e, [--environment=ENVIRONMENT]  # Environment to rebuild
    -c, [--account=ACCOUNT]          # Name of the account in which the environment can be found

#### ey rollback

Uses code from previous deploy in the `/data/APP_NAME/releases` directory on
remote server(s) to restart application servers.

Options:

    -v, [--verbose]                  # Be verbose
    -a, [--app=APP]                  # Name of the application to roll back
    -e, [--environment=ENVIRONMENT]  # Environment in which to roll back the application
    -c, [--account=ACCOUNT]          # Name of the account in which the environment can be found

#### ey recipes apply

This is similar to `ey rebuild` except Engine Yard's main configuration step is skipped. This command only works on stacks older than stable v5. You will want to use `ey rebuild` for stable v5 cookbooks to run.

Options:

    -e, [--environment=ENVIRONMENT]  # Environment in which to apply recipes
    -c, [--account=ACCOUNT]          # Name of the account in which the environment can be found

#### ey recipes upload

The current directory should contain a subdirectory named `cookbooks` to be
uploaded.

Options:

    -e, [--environment=ENVIRONMENT]  # Environment that will receive the recipes
    -c, [--account=ACCOUNT]          # Name of the account in which the environment can be found
        [--apply]                    # Apply the recipes (same as above) immediately after uploading
    -f, [--file=FILE]                # Specify a gzipped tar file (.tgz) for upload instead of cookbooks/ directory

#### ey recipes download

The recipes will be unpacked into a directory called `cookbooks` in the current
directory. If the cookbooks directory already exists, an error will be raised.

Options:

    -e, [--environment=ENVIRONMENT]  # Environment for which to download the recipes
    -c, [--account=ACCOUNT]          # Name of the account in which the environment can be found

#### ey web enable

Remove the maintenance page for this application in the given environment.

Options:

    -v, [--verbose]                  # Be verbose
    -a, [--app=APP]                  # Name of the application whose maintenance page will be removed
    -e, [--environment=ENVIRONMENT]  # Environment on which to take down the maintenance page
    -c, [--account=ACCOUNT]          # Name of the account in which the environment can be found

#### ey web disable

The maintenance page is taken from the app currently being deployed. This means
that you can customize maintenance pages to tell users the reason for downtime
on every particular deploy.

Maintenance pages searched for in order of decreasing priority:

  * public/maintenance.html.custom
  * public/maintenance.html.tmp
  * public/maintenance.html
  * public/system/maintenance.html.default

Options:

    -v, [--verbose]                  # Be verbose
    -a, [--app=APP]                  # Name of the application whose maintenance page will be put up
    -e, [--environment=ENVIRONMENT]  # Environment on which to put up the maintenance page
    -c, [--account=ACCOUNT]          # Name of the account in which the environment can be found

#### ey web restart

Restarts the application servers for the given application. Enables maintenance
pages if it would be enabled during a normal deploy. Respects the
`maintenance_on_restart` ey.yml configuration.

Options:

    -v, [--verbose]                  # Be verbose
    -a, [--app=APP]                  # Name of the application to restart
    -e, [--environment=ENVIRONMENT]  # Name of the environment to restart
    -c, [--account=ACCOUNT]          # Name of the account in which the app and environment can be found

#### ey ssh

If a command is supplied, it will be run, otherwise a session will be opened.
The application master is used for environments with clusters. Option `--all`
requires a command to be supplied and runs it on all servers.

Note: this command is a bit picky about its ordering. To run a command with
arguments on all servers, like `rm -f /some/file`, you need to order it like so:

    $ ey ssh "rm -f /some/file" -e my-environment --all

Options:

        [--utilities=one two three]  # Run command on the utility servers with the given names. If no names are given, run on all utility servers.
        [--app-servers]              # Run command on all application servers
        [--db-servers]               # Run command on the database servers
        [--db-master]                # Run command on the master database server
    -A, [--all]                      # Run command on all servers
        [--db-slaves]                # Run command on the slave database servers
    -e, [--environment=ENVIRONMENT]  # Name of the environment to ssh into
    -c, [--account=ACCOUNT]          # Name of the account in which the environment can be found
    -s, [--shell]                    # Use a particular shell instead of the default bash
        [--no-shell]                 # Don't use a shell to run the command (default behavior of ssh)

#### ey launch

Open the application in a browser.

Options:

    -c, [--account=ACCOUNT]          # Name of the account in which the environment can be found
    -a, [--app=APP]                  # Name of the application to launch
    -e, [--environment=ENVIRONMENT]  # Name of the environment for the application

#### ey whoami

Who am I logged in as? Prints the name and email of the current logged in user.

#### ey login

Log in and verify access to EY Cloud. Use logout first if you need to switch
user accounts.

#### ey logout

Remove the current API key from `~/.eyrc` or file at env variable `$EYRC`


### Global Options

All commands accept the following options.

    --api-token=API_TOKEN                    # Use API-TOKEN to authenticate this command
    --serverside-version=SERVERSIDE_VERSION  # Please use with care! Override deploy system version
                                             # (same as ENV variable ENGINEYARD_SERVERSIDE_VERSION)

Not all commands will make use of these options. For example,
ey status does not use, and will ignore the --serverside-version flag.

Also, please consider that it's usually not a good idea to override the
version of serverside unless you know what you're doing. CLI and serverside
versions are designed to work together and mixing them can cause errors.


### API Client

See [engineyard-cloud-client](https://github.com/engineyard/engineyard-cloud-client) for the API client library.

### DEBUG

The API commands will print internal information if `$DEBUG` is set:

    $ DEBUG=1 ey environments --all
           GET  https://cloud.engineyard.com/api/v2/apps
        Params  {"no_instances"=>"true"}
       Headers  {"User-Agent"=>"EngineYard/2.0.0 EngineYardCloudClient/1.0.5",
                "Accept"=>"application/json",
                "X-EY-Cloud-Token"=>"YOURTOKEN"}
      Response  {"apps"=>
                  [{"environments"=>[],
                    "name"=>"myapp",
                    "repository_uri"=>"git@github.com:myaccount/myapp.git",
                    "app_type_id"=>"rails3",
                    "account"=>{"name"=>"myaccount", "id"=>1234},
                    "id"=>12345}]}

### Releasing

To release the engineyard gem, use the command below and then follow the
instructions it outputs.

    bundle exec rake release

This will remove the `.pre` from the current version, then bump the patch level
and add `.pre` after for the next version. The version will be tagged in git.

To release a new `engineyard-serverside` gem that has already been pushed to
rubygems.org, update `lib/engineyard/version.rb` to refer to the
`engineyard-serverside` version you want to release, then make a commit.
Each engineyard gem is hard-linked to a specific default engineyard-serverside
version which can be overriden with the `--serverside-version` option.

The `engineyard-serverside-adapter` version does not need to be bumped in the
gemspec unless you're also releasing a new version of that gem. Versions
of adapter are no longer linked to serverside.
