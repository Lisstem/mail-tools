# frozen_string_literal: true

require "pg"

module MailTools
  class DB
    def initialize(host: 'localhost', port: 5432, dbname: "mail", user: nil, password: nil)
      raise Error unless user && password

      @connection_params = { host:, port:, dbname:, user:, password: }
    end

    def connection
      @connection ||= PG::Connection.new(@connection_params)
    end

    def close
      @connection&.close
    end

    def self.from_config
      new(**MailTools::Config.config.transform_keys(&:to_sym).slice(:host, :user, :port, :dbname, :password))
    end
  end
end
