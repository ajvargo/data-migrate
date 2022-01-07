module DataMigrate
  class StatusService
    class << self
      def dump(connection = ActiveRecord::Base.connection, stream = STDOUT)
        new(connection).dump(stream)
        stream
      end
    end

    def initialize(connection)
      @connection = connection
    end

    def root_folder
      Rails.root
    end

    def dump(stream)
      output(stream)
    end

    private

    def table_name
      DataMigrate::DataSchemaMigration.table_name
    end

    def output(stream)
      unless DataMigrate::DataSchemaMigration.table_exists?
        stream.puts "Data migrations table does not exist yet."
        return
      end

      # output
      stream.puts "\ndatabase: #{database}\n\n"
      stream.puts "#{'Status'.center(8)}  #{'Migration ID'.ljust(14)}  Migration Name"
      stream.puts "-" * 50
      db_list.each do |status, version, name|
        stream.puts "#{status.center(8)}  #{version.ljust(14)}  #{name}"
      end
      stream.puts
    end

    def database
      ActiveRecord::Base.connection_db_config.database
    end

    def db_list
      DataMigrate::DataMigrator.migrations_status
    end
  end
end
