# frozen_string_literal: true

require_relative "base"

module MailTools
  module Command
    class Teardown < Base
      def default
        users
        addresses
        domains
      end
      
      %i[domains addresses users].each do |sym|
        define_method sym do
          result = db.exec("DROP TABLE IF EXISTS #{sym.to_s};")
        end
      end
    end
  end
end
