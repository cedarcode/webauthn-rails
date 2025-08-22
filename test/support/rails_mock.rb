require "ostruct"

# Minimal Rails application mock - just what generators need
module Rails
  class << self
    def application
      @application ||= OpenStruct.new(
        root: File.dirname(__FILE__),
        config: OpenStruct.new(
          root: File.dirname(__FILE__),
          paths: {
            "db/migrate" => [ "db/migrate" ],
            "db" => [ "db" ]
          },
          active_record: OpenStruct.new(
            configurations: OpenStruct.new(configs_for: -> { [] }),
            belongs_to_required_by_default: false
          )
        )
      )
    end
  end
end
