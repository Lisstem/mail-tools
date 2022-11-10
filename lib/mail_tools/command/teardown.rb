# frozen_string_literal: true

require_relative "base"

module MailTools
  module Command
    class Teardown < Base
      def default
        addresses
        domains
      end

      def domains
        result = db.exec("DROP TABLE IF EXISTS domains;")
        result.check
      end

      def addresses
        result = db.exec("DROP TABLE IF EXISTS addresses;")
        result.check
      end
    end
  end
end
