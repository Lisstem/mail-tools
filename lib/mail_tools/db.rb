require "pg"

module MailTools
  module DB
    class << self
      attr_reader :connection

      def init(host: 'localhost', port: 5432, dbname: "mail", user: nil, password: nil)
        raise Error unless user && password

        @connection = PG::Connection.new(host:, port:, dbname:, user:, password:)
      end

      def close
        @connection&.close
      end

      def init_with_config
        init(**MailTools::Config.config.transform_keys(&:to_sym).slice(:host, :user, :port, :dbname, :password))
      end
    end
  end
end
