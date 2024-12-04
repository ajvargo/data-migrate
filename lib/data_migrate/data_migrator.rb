# frozen_string_literal: true

require "active_record"
require "data_migrate/config"

module DataMigrate
  class DataMigrator < ActiveRecord::Migrator
    def load_migrated
      @migrated_versions =
        DataMigrate::RailsHelper.data_schema_migration.normalized_versions.map(&:to_i).sort
    end

    class << self
      def migrations_paths
        Array.wrap(DataMigrate.config.data_migrations_path)
      end

      def create_data_schema_table
        DataMigrate::RailsHelper.data_schema_migration.create_table
      end

      def current_version
        DataMigrate::MigrationContext.new(migrations_paths).current_version
      end

      ##
      # Compares the given filename with what we expect data migration
      # filenames to be, eg the "20091231235959_some_name.rb" pattern
      # @param (String) filename
      # @return (MatchData)
      def match(filename)
        /(\d{14})_(.+)\.rb$/.match(filename)
      end

      def needs_migration?
        DataMigrate::DatabaseTasks.pending_migrations.count.positive?
      end
      ##
      # Provides the full migrations_path filepath
      # @return (String)
      def full_migrations_path
        File.join(Rails.root, *migrations_paths.split(File::SEPARATOR))
      end

      def migrations_status
        DataMigrate::MigrationContext.new(migrations_paths).migrations_status
      end

      # TODO: this was added to be backward compatible, need to re-evaluate
      def migrations(_migrations_paths)
        DataMigrate::MigrationContext.new(_migrations_paths).migrations
      end

      #TODO: this was added to be backward compatible, need to re-evaluate
      def run(direction, migration_paths, version)
        # Ensure all Active Record model cache is reset for each data migration
        # As recommended in: https://github.com/rails/rails/blob/da21c2e9812e5eb0698fba4a9aa38632fc004432/activerecord/lib/active_record/migration.rb#L467-L470
        ActiveRecord::Base.descendants.each(&:reset_column_information)

        DataMigrate::MigrationContext.new(migration_paths).run(direction, version)
      end

      def rollback(migrations_path, steps)
        DataMigrate::MigrationContext.new(migrations_path).rollback(steps)
      end
    end

    private

    def record_version_state_after_migrating(version)
      if down?
        migrated.delete(version)
        DataMigrate::RailsHelper.data_schema_delete_version(version.to_s)
      else
        migrated << version
        DataMigrate::RailsHelper.data_schema_migration.create_version(version.to_s)
      end
    end
  end
end
