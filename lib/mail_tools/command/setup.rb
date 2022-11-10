# frozen_string_literal: true

require_relative "base"

module MailTools
  module Command
    class Setup < Base
      def default
        domains
        addresses
      end

      def domains
        result = db.exec("CREATE TABLE IF NOT EXISTS domains ("\
                         "id serial PRIMARY KEY NOT NULL,"\
                         "name text UNIQUE NOT NULL"\
                         ");")
        result.check
      end

      def addresses
        result = db.exec("CREATE TABLE IF NOT EXISTS addresses ("\
                         "id serial PRIMARY KEY NOT NULL, "\
                         "name text NOT NULL, "\
                         "domain_id int NOT NULL REFERENCES domains(id) ON DELETE CASCADE, "\
                         "UNIQUE (name, domain_id)"\
                         ");")
        result.check
      end
    end
  end
end
