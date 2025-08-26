module Rails
  class << self
    def application
      @application ||= MockApplication.new
    end
  end

  # Mock application that provides only the config methods needed by generators
  class MockApplication
    def config
      @config ||= MockConfig.new
    end
  end

  # Mock config that provides paths and active_record configuration
  class MockConfig
    # Used by migration generators to find db/migrate directory
    def paths
      {
        "db/migrate" => [ "db/migrate" ],
        "db" => [ "db" ]
      }
    end

    # Used by ActiveRecord generators for configuration
    def active_record
      @active_record ||= MockActiveRecordConfig.new
    end

    def root
      File.expand_path("../../tmp", __FILE__)
    end
  end

  # Mock ActiveRecord config
  class MockActiveRecordConfig
    def belongs_to_required_by_default
      false
    end
  end
end
