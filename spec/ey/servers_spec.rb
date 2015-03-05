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
    expect(@out).to match(/#{scenario[:environment]}/) if scenario[:environment]
    expect(@out).to match(/#{scenario[:account]}/) if scenario[:account]
  end

  include_examples "it takes an environment name and an account name"

  context "with no servers" do
    before do
      login_scenario "empty"
    end

    it "prints error when no application found" do
      fast_failing_ey %w[servers]
      expect(@err).to match(/No application found/)
    end
  end

  context "with 1 server" do
    before(:all) do
      login_scenario "one app, many environments"
    end

    it "lists the servers with specified env" do
      fast_ey %w[servers -e giblets]
      expect(@out).to match(/main \/ giblets/)
      expect(@out).to include('1 server ')
    end
  end

  context "with servers" do
    before(:all) do
      login_scenario "two accounts, two apps, two environments, ambiguous"
    end

    it "lists the servers with specified env" do
      fast_ey %w[servers -c main -e giblets]
      expect(@out).to include("# 7 servers on main / giblets")
      expect(@out).to include("app_master_hostname.compute-1.amazonaws.com \ti-ddbbdd92\tapp_master")
      expect(@out).to include("app_hostname.compute-1.amazonaws.com        \ti-d2e3f1b9\tapp")
      expect(@out).to include("db_master_hostname.compute-1.amazonaws.com  \ti-d4cdddbf\tdb_master")
      expect(@out).to include("db_slave_1_hostname.compute-1.amazonaws.com \ti-asdfasdfaj\tdb_slave  \tSlave I")
      expect(@out).to include("db_slave_2_hostname.compute-1.amazonaws.com \ti-asdfasdfaj\tdb_slave")
      expect(@out).to include("util_fluffy_hostname.compute-1.amazonaws.com\ti-80e3f1eb\tutil      \tfluffy")
      expect(@out).to include("util_rocky_hostname.compute-1.amazonaws.com \ti-80etf1eb\tutil      \trocky")
    end

    it "lists the servers with specified env with users" do
      fast_ey %w[servers -c main -e giblets -u]
      expect(@out).to include("# 7 servers on main / giblets")
      expect(@out).to include("turkey@app_master_hostname.compute-1.amazonaws.com \ti-ddbbdd92\tapp_master")
      expect(@out).to include("turkey@app_hostname.compute-1.amazonaws.com        \ti-d2e3f1b9\tapp")
      expect(@out).to include("turkey@db_master_hostname.compute-1.amazonaws.com  \ti-d4cdddbf\tdb_master")
      expect(@out).to include("turkey@db_slave_1_hostname.compute-1.amazonaws.com \ti-asdfasdfaj\tdb_slave  \tSlave I")
      expect(@out).to include("turkey@db_slave_2_hostname.compute-1.amazonaws.com \ti-asdfasdfaj\tdb_slave")
      expect(@out).to include("turkey@util_fluffy_hostname.compute-1.amazonaws.com\ti-80e3f1eb\tutil      \tfluffy")
      expect(@out).to include("turkey@util_rocky_hostname.compute-1.amazonaws.com \ti-80etf1eb\tutil      \trocky")
    end

    it "lists simple format servers" do
      fast_ey %w[servers -c main -e giblets -qs], :debug => false
      expect(@out.split(/\n/).map {|x| x.split(/\t/) }).to eq([
        ['app_master_hostname.compute-1.amazonaws.com',  'i-ddbbdd92',   'app_master'         ],
        ['app_hostname.compute-1.amazonaws.com',         'i-d2e3f1b9',   'app'                ],
        ['db_master_hostname.compute-1.amazonaws.com',   'i-d4cdddbf',   'db_master'          ],
        ['db_slave_1_hostname.compute-1.amazonaws.com',  'i-asdfasdfaj', 'db_slave', 'Slave I'],
        ['db_slave_2_hostname.compute-1.amazonaws.com',  'i-asdfasdfaj', 'db_slave'           ],
        ['util_fluffy_hostname.compute-1.amazonaws.com', 'i-80e3f1eb',   'util',     'fluffy' ],
        ['util_rocky_hostname.compute-1.amazonaws.com',  'i-80etf1eb',   'util',     'rocky'  ],
      ])
    end

    it "lists simple format servers with users" do
      fast_ey %w[servers -c main -e giblets -qsu], :debug => false
      expect(@out.split(/\n/).map {|x| x.split(/\t/) }).to eq([
        ['turkey@app_master_hostname.compute-1.amazonaws.com',  'i-ddbbdd92',   'app_master'         ],
        ['turkey@app_hostname.compute-1.amazonaws.com',         'i-d2e3f1b9',   'app'                ],
        ['turkey@db_master_hostname.compute-1.amazonaws.com',   'i-d4cdddbf',   'db_master'          ],
        ['turkey@db_slave_1_hostname.compute-1.amazonaws.com',  'i-asdfasdfaj', 'db_slave', 'Slave I'],
        ['turkey@db_slave_2_hostname.compute-1.amazonaws.com',  'i-asdfasdfaj', 'db_slave'           ],
        ['turkey@util_fluffy_hostname.compute-1.amazonaws.com', 'i-80e3f1eb',   'util',     'fluffy' ],
        ['turkey@util_rocky_hostname.compute-1.amazonaws.com',  'i-80etf1eb',   'util',     'rocky'  ],
      ])
    end

    it "lists host only" do
      fast_ey %w[servers -c main -e giblets -qS], :debug => false
      expect(@out.split(/\n/)).to eq([
        'app_master_hostname.compute-1.amazonaws.com',
        'app_hostname.compute-1.amazonaws.com',
        'db_master_hostname.compute-1.amazonaws.com',
        'db_slave_1_hostname.compute-1.amazonaws.com',
        'db_slave_2_hostname.compute-1.amazonaws.com',
        'util_fluffy_hostname.compute-1.amazonaws.com',
        'util_rocky_hostname.compute-1.amazonaws.com',
      ])
    end

    it "lists host only with users" do
      fast_ey %w[servers -c main -e giblets -qSu], :debug => false
      expect(@out.split(/\n/)).to eq([
        'turkey@app_master_hostname.compute-1.amazonaws.com',
        'turkey@app_hostname.compute-1.amazonaws.com',
        'turkey@db_master_hostname.compute-1.amazonaws.com',
        'turkey@db_slave_1_hostname.compute-1.amazonaws.com',
        'turkey@db_slave_2_hostname.compute-1.amazonaws.com',
        'turkey@util_fluffy_hostname.compute-1.amazonaws.com',
        'turkey@util_rocky_hostname.compute-1.amazonaws.com',
      ])
    end

    it "lists servers constrained to app servers" do
      fast_ey %w[servers -c main -e giblets -qs --app-servers], :debug => false
      expect(@out.split(/\n/).map {|x| x.split(/\t/) }).to eq([
        ['app_master_hostname.compute-1.amazonaws.com',  'i-ddbbdd92',   'app_master'         ],
        ['app_hostname.compute-1.amazonaws.com',         'i-d2e3f1b9',   'app'                ],
      ])
    end

    it "lists servers constrained to db servers" do
      fast_ey %w[servers -c main -e giblets -qs --db-servers], :debug => false
      expect(@out.split(/\n/).map {|x| x.split(/\t/) }).to eq([
        ['db_master_hostname.compute-1.amazonaws.com',   'i-d4cdddbf',   'db_master'          ],
        ['db_slave_1_hostname.compute-1.amazonaws.com',  'i-asdfasdfaj', 'db_slave', 'Slave I'],
        ['db_slave_2_hostname.compute-1.amazonaws.com',  'i-asdfasdfaj', 'db_slave'           ],
      ])
    end

    it "lists servers constrained to db master" do
      fast_ey %w[servers -c main -e giblets -qs --db-master], :debug => false
      expect(@out.split(/\n/).map {|x| x.split(/\t/) }).to eq([
        ['db_master_hostname.compute-1.amazonaws.com',   'i-d4cdddbf',   'db_master'          ],
      ])
    end

    it "lists servers constrained to db slaves" do
      fast_ey %w[servers -c main -e giblets -qs --db-slaves], :debug => false
      expect(@out.split(/\n/).map {|x| x.split(/\t/) }).to eq([
        ['db_slave_1_hostname.compute-1.amazonaws.com',  'i-asdfasdfaj', 'db_slave', 'Slave I'],
        ['db_slave_2_hostname.compute-1.amazonaws.com',  'i-asdfasdfaj', 'db_slave'           ],
      ])
    end

    it "lists servers constrained to utilities" do
      fast_ey %w[servers -c main -e giblets -qs --utilities], :debug => false
      expect(@out.split(/\n/).map {|x| x.split(/\t/) }).to eq([
        ['util_fluffy_hostname.compute-1.amazonaws.com', 'i-80e3f1eb',   'util',     'fluffy' ],
        ['util_rocky_hostname.compute-1.amazonaws.com',  'i-80etf1eb',   'util',     'rocky'  ],
      ])
    end

    it "lists servers constrained to utilities with names" do
      fast_ey %w[servers -c main -e giblets -qs --utilities fluffy], :debug => false
      expect(@out.split(/\n/).map {|x| x.split(/\t/) }).to eq([
        ['util_fluffy_hostname.compute-1.amazonaws.com', 'i-80e3f1eb',   'util',     'fluffy' ],
      ])
    end

    it "lists servers constrained to app servers and utilities" do
      fast_ey %w[servers -c main -e giblets -qs --app --util], :debug => false
      expect(@out.split(/\n/).map {|x| x.split(/\t/) }).to eq([
        ['app_master_hostname.compute-1.amazonaws.com',  'i-ddbbdd92',   'app_master'         ],
        ['app_hostname.compute-1.amazonaws.com',         'i-d2e3f1b9',   'app'                ],
        ['util_fluffy_hostname.compute-1.amazonaws.com', 'i-80e3f1eb',   'util',     'fluffy' ],
        ['util_rocky_hostname.compute-1.amazonaws.com',  'i-80etf1eb',   'util',     'rocky'  ],
      ])
    end

    it "lists servers constrained to app or util with name" do
      fast_ey %w[servers -c main -e giblets -qs --app --util rocky], :debug => false
      expect(@out.split(/\n/).map {|x| x.split(/\t/) }).to eq([
        ['app_master_hostname.compute-1.amazonaws.com',  'i-ddbbdd92',   'app_master'         ],
        ['app_hostname.compute-1.amazonaws.com',         'i-d2e3f1b9',   'app'                ],
        ['util_rocky_hostname.compute-1.amazonaws.com',  'i-80etf1eb',   'util',     'rocky'  ],
      ])
    end

    it "finds no servers with gibberish " do
      fast_failing_ey %w[servers --account main --environment gibberish]
      expect(@err).to include('No environment found matching "gibberish"')
    end

    it "finds no servers with gibberish account" do
      fast_failing_ey %w[servers --account gibberish --environment giblets]
      expect(@err).to include('No account found matching "gibberish"')
    end

    it "reports failure to find a git repo when not in one" do
      Dir.chdir(Dir.tmpdir) do
        fast_failing_ey %w[servers]
        expect(@err).to match(/fatal: Not a git repository \(or any of the parent directories\): .*#{Regexp.escape(Dir.tmpdir)}/)
        expect(@out).not_to match(/no application configured/)
      end
    end
  end
end
