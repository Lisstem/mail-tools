# frozen_string_literal: true

require_relative "base"

module MailTools
  module Command
    class Setup < Base
      def default
        domains
      end

      def domains
        result = db.exec("CREATE TABLE IF NOT EXISTS domains ("\
                         "id serial PRIMARY KEY NOT NULL,"\
                         "name text UNIQUE NOT NULL"\
                         ");")
        result.check
      end
    end
  end
end