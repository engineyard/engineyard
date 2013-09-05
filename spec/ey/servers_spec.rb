require 'spec_helper'

describe "ey servers" do

  given "integration"

  def command_to_run(opts)
    cmd = ["servers"]
    cmd << "--environment" << opts[:environment] if opts[:environment]
    cmd << "--account"     << opts[:account]     if opts[:account]
    cmd
  end

  def verify_ran(scenario)
    @out.should match(/#{scenario[:environment]}/) if scenario[:environment]
    @out.should match(/#{scenario[:account]}/) if scenario[:account]
  end

  include_examples "it takes an environment name and an account name"

  context "with no servers" do
    before do
      login_scenario "empty"
    end

    it "prints error when no application found" do
      fast_failing_ey %w[servers]
      @err.should =~ /No application found/
    end
  end

  context "with 1 server" do
    before(:all) do
      login_scenario "one app, many environments"
    end

    it "lists the servers with specified env" do
      fast_ey %w[servers -e giblets]
      @out.should =~ /main \/ giblets/
      @out.should include('1 server ')
    end
  end

  context "with servers" do
    before(:all) do
      login_scenario "two accounts, two apps, two environments, ambiguous"
    end

    it "lists the servers with specified env" do
      fast_ey %w[servers -c main -e giblets]
      @out.should include("# 7 servers on main / giblets")
      @out.should include("app_master_hostname.compute-1.amazonaws.com \ti-ddbbdd92\tapp_master")
      @out.should include("app_hostname.compute-1.amazonaws.com        \ti-d2e3f1b9\tapp")
      @out.should include("db_master_hostname.compute-1.amazonaws.com  \ti-d4cdddbf\tdb_master")
      @out.should include("db_slave_1_hostname.compute-1.amazonaws.com \ti-asdfasdfaj\tdb_slave  \tSlave I")
      @out.should include("db_slave_2_hostname.compute-1.amazonaws.com \ti-asdfasdfaj\tdb_slave")
      @out.should include("util_fluffy_hostname.compute-1.amazonaws.com\ti-80e3f1eb\tutil      \tfluffy")
      @out.should include("util_rocky_hostname.compute-1.amazonaws.com \ti-80etf1eb\tutil      \trocky")
    end

    it "lists the servers with specified env with users" do
      fast_ey %w[servers -c main -e giblets -u]
      @out.should include("# 7 servers on main / giblets")
      @out.should include("turkey@app_master_hostname.compute-1.amazonaws.com \ti-ddbbdd92\tapp_master")
      @out.should include("turkey@app_hostname.compute-1.amazonaws.com        \ti-d2e3f1b9\tapp")
      @out.should include("turkey@db_master_hostname.compute-1.amazonaws.com  \ti-d4cdddbf\tdb_master")
      @out.should include("turkey@db_slave_1_hostname.compute-1.amazonaws.com \ti-asdfasdfaj\tdb_slave  \tSlave I")
      @out.should include("turkey@db_slave_2_hostname.compute-1.amazonaws.com \ti-asdfasdfaj\tdb_slave")
      @out.should include("turkey@util_fluffy_hostname.compute-1.amazonaws.com\ti-80e3f1eb\tutil      \tfluffy")
      @out.should include("turkey@util_rocky_hostname.compute-1.amazonaws.com \ti-80etf1eb\tutil      \trocky")
    end

    it "lists simple format servers" do
      fast_ey %w[servers -c main -e giblets -qs], :debug => false
      @out.split(/\n/).map {|x| x.split(/\t/) }.should == [
        ['app_master_hostname.compute-1.amazonaws.com',  'i-ddbbdd92',   'app_master'         ],
        ['app_hostname.compute-1.amazonaws.com',         'i-d2e3f1b9',   'app'                ],
        ['db_master_hostname.compute-1.amazonaws.com',   'i-d4cdddbf',   'db_master'          ],
        ['db_slave_1_hostname.compute-1.amazonaws.com',  'i-asdfasdfaj', 'db_slave', 'Slave I'],
        ['db_slave_2_hostname.compute-1.amazonaws.com',  'i-asdfasdfaj', 'db_slave'           ],
        ['util_fluffy_hostname.compute-1.amazonaws.com', 'i-80e3f1eb',   'util',     'fluffy' ],
        ['util_rocky_hostname.compute-1.amazonaws.com',  'i-80etf1eb',   'util',     'rocky'  ],
      ]
    end

    it "lists simple format servers with users" do
      fast_ey %w[servers -c main -e giblets -qsu], :debug => false
      @out.split(/\n/).map {|x| x.split(/\t/) }.should == [
        ['turkey@app_master_hostname.compute-1.amazonaws.com',  'i-ddbbdd92',   'app_master'         ],
        ['turkey@app_hostname.compute-1.amazonaws.com',         'i-d2e3f1b9',   'app'                ],
        ['turkey@db_master_hostname.compute-1.amazonaws.com',   'i-d4cdddbf',   'db_master'          ],
        ['turkey@db_slave_1_hostname.compute-1.amazonaws.com',  'i-asdfasdfaj', 'db_slave', 'Slave I'],
        ['turkey@db_slave_2_hostname.compute-1.amazonaws.com',  'i-asdfasdfaj', 'db_slave'           ],
        ['turkey@util_fluffy_hostname.compute-1.amazonaws.com', 'i-80e3f1eb',   'util',     'fluffy' ],
        ['turkey@util_rocky_hostname.compute-1.amazonaws.com',  'i-80etf1eb',   'util',     'rocky'  ],
      ]
    end

    it "finds no servers with gibberish " do
      fast_failing_ey %w[servers --account main --environment gibberish]
      @err.should include('No environment found matching "gibberish"')
    end

    it "finds no servers with gibberish account" do
      fast_failing_ey %w[servers --account gibberish --environment giblets]
      @err.should include('No account found matching "gibberish"')
    end

    it "reports failure to find a git repo when not in one" do
      Dir.chdir(Dir.tmpdir) do
        fast_failing_ey %w[servers]
        @err.should =~ /fatal: Not a git repository \(or any of the parent directories\): .*#{Regexp.escape(Dir.tmpdir)}/
        @out.should_not =~ /no application configured/
      end
    end
  end
end
