# frozen_string_literal: true

require_relative "base"

module MailTools
  module Command
    class List < Base
      def domains
        result = db.exec("SELECT name FROM domains;")
        result.check
        result.each_row { |row| puts row }
      end

      def addresses
        result = db.exec("SELECT addresses.name, domains.name FROM addresses JOIN domains ON domains.id = domain_id")
        result.check
        result.each_row { |row| puts row.join("@") }
      end

      def users
        result = db.exec "SELECT users.name, addresses.name, domains.name FROM users "\
                         "INNER JOIN addresses ON addresses.id = address_id "\
                         "INNER JOIN domains ON domains.id = domain_id;"
        result.check
        result.each_row { |row| puts("%s <%s@%s>" % row) }
      end

      ALIAS_QUERY = "WITH mail AS (SELECT addresses.id AS id, addresses.name AS address_name, domains.name AS domain_name "\
                    "FROM addresses INNER JOIN domains ON domains.id = domain_id) "\
                    "SELECT source.address_name, source.domain_name, destination.address_name, destination.domain_name "\
                    "FROM mail AS source INNER JOIN aliases ON source.id = source_id "\
                    "INNER JOIN mail AS destination ON destination.id = destination_id;"
      def aliases
        result = db.exec(ALIAS_QUERY)
        result.check
        length = lengths(result, header: false)
        result.each_row do |row|
          puts(length.each_slice(2).map { |s| "%-#{s.sum + 1}s" }.join(" => ") %
                 row.each_slice(2).map { |s| s.join("@") })
        end
      end
    end
  end
end
