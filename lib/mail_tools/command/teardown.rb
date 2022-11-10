# frozen_string_literal: true

require_relative "base"

module MailTools
  module Command
    class Teardown < Base
      def default
        domains
      end

      def domains
        result = db.exec("DROP TABLE IF EXISTS domains;")
        result.check
      end
    end
  end
end
