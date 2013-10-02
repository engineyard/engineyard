require 'spec_helper'

describe "ey init" do
  given "integration"

  let(:default_migration_command) { "rake db:migrate --trace" }

  before do
    login_scenario "one app, one environment"
  end

  before { clean_ey_yml }
  after  { clean_ey_yml }

  context "with no ey.yml file" do
    it "writes the file" do
      fast_ey %w[init]

      expect(ey_yml).to exist
      expect_config('migrate').to eq(false)
    end
  end

  context "with existing ey.yml file" do
    let(:existing) {
      {
        "defaults" => {
          "migrate" => false,
          "migration_command" => "thor fancy:migrate",
          "precompile_assets" => false,
          "precompile_assets_task" => "assets:precompile",
        },
        "environments" => {
          "my_env" => {
            "default" => true,
            "migrate" => true,
            "migration_command" => default_migration_command,
          }
        }
      }
    }

    before do
      write_yaml(existing, 'ey.yml')
    end

    it "reinitializes the file" do
      fast_ey %w[init]

      expect_config('defaults','migration_command').to eq("thor fancy:migrate")
      expect_config('defaults','migrate').to eq(false)
      expect_config('defaults','precompile_assets').to eq(false)

      expect_config('environments','my_env','default').to eq(true)
      expect_config('environments','my_env','migrate').to eq(true)
      expect_config('environments','my_env','migration_command').to eq(default_migration_command)
    end

    it "makes a backup when overwriting an existing file" do
      fast_ey %w[init]
      data = read_yaml('ey.yml.backup')
      expect(data['defaults']['migration_command']).to eq('thor fancy:migrate')
    end
  end

  context "smart defaults" do
    describe "migrate" do
      let(:db) { Pathname.new('db') }
      let(:db_migrate) { db.join('migrate') }

      context "with db/migrate directory" do
        before { db_migrate.mkpath }
        after { db.rmtree }

        it "sets migrate to true and uses default migration command" do
          fast_ey %w[init]

          expect_config('migrate').to eq(true)
          expect_config('migration_command').to eq(default_migration_command)
        end
      end

      context "without db/migrate directory" do
        it "sets migrate to false and doesn't write migration_command" do
          expect(db_migrate).to_not exist

          fast_ey %w[init]

          expect_config('migrate').to eq(false)
          expect_config('migration_command').to be_nil
        end
      end
    end

    context "precompile_assets" do
      let(:app) { Pathname.new('app') }
      let(:assets) { app.join('assets') }

      context "with app/assets directory" do
        before { assets.mkpath }
        after { app.rmtree }

        it "sets precompile_assets to true and doesn't write precompile_assets_task" do
          fast_ey %w[init]

          expect_config('precompile_assets').to eq(true)
          expect_config('precompile_assets_task').to be_nil
        end
      end

      context "without app/assets directory" do
        it "sets precompile_assets to false and does not set an precompile_assets_task" do
          expect(assets).to_not exist

          fast_ey %w[init]

          expect_config('precompile_assets').to eq(false)
          expect_config('precompile_assets_task').to be_nil
        end
      end
    end
  end
end
