# frozen_string_literal: true

require_relative "base"

module MailTools
  module Command
    class Setup < Base
      def default
        domains
        addresses
        users
        aliases
      end

      # rubocop:disable Layout/HashAlignment
      QUERIES = { domains:   "CREATE TABLE IF NOT EXISTS domains ("\
                              "id serial PRIMARY KEY NOT NULL,"\
                              "name text UNIQUE NOT NULL"\
                              ");",
                  addresses:  "CREATE TABLE IF NOT EXISTS addresses ("\
                              "id serial PRIMARY KEY NOT NULL, "\
                              "name text NOT NULL, "\
                              "domain_id int NOT NULL REFERENCES domains(id) ON DELETE CASCADE, "\
                              "UNIQUE (name, domain_id)"\
                              ");",
                  users:      "CREATE TABLE IF NOT EXISTS users ("\
                              "id serial PRIMARY KEY NOT NULL, "\
                              "name text UNIQUE NOT NULL, "\
                              "password text NOT NULL, "\
                              "address_id int NOT NULL UNIQUE REFERENCES addresses(id) ON DELETE CASCADE"\
                              ");",
                  aliases:    "CREATE TABLE IF NOT EXISTS aliases ("\
                             "id serial PRIMARY KEY NOT NULL, "\
                             "source_id INT NOT NULL REFERENCES addresses(id) ON DELETE CASCADE,"\
                             "destination_id INT NOT NULL REFERENCES addresses(id) ON DELETE CASCADE, "\
                             "UNIQUE (source_id, destination_id)"\
                             ");" }.freeze
      # rubocop:enable Layout/HashAlignment

      QUERIES.each_pair do |sym, query|
        define_method sym do
          result = db.exec(query)
          result.check
        end
      end
    end
  end
end
