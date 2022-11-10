# frozen_string_literal: true

require_relative "base"

module MailTools
  module Command
    class Teardown < Base
      def default
        aliases
        users
        addresses
        domains
      end
      
      %i[domains addresses users aliases].each do |sym|
        define_method sym do
          result = db.exec("DROP TABLE IF EXISTS #{sym};")
          result.check
        end
      end
    end
  end
end
