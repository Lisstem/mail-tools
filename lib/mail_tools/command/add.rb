# frozen_string_literal: true

require_relative "base"
require_relative "input"

module MailTools
  module Command
    class Add < Base
      def domains(*names)
        query = "INSERT INTO domains (name) VALUES #{(1..names.length).map { |i| "($#{i})" }.join(", ")};"
        result = db.exec_params(query, names)
        result.check
      end

      def addresses(*addresses)
        create_addresses(addresses)
      end
      
      def user(name, address, password = nil, create: true)
        password = Input.encrypted_password(password)
        query = "INSERT INTO users(name, password, address_id) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING;"
        db.transaction do |conn|
          address = create ? get_or_create_addresses([address], conn) : get_addresses([address], conn)
          raise Error if address.blank?

          result = conn.exec_params(query, [name, password, address[0]["id"]])
          result.check
        end
      end

      def alias(source, destination, create: true)
        addresses = [source, destination]
        db.transaction do |conn|
          addresses = create ? get_or_create_addresses(addresses, conn) : get_addresses(addresses, conn)
          raise Error unless addresses.count == 2

          result = conn.exec_params("INSERT INTO aliases(source_id, destination_id) "\
                                    "VALUES ($1, $2) ON CONFLICT DO NOTHING", addresses.map { |add| add["id"] })
          result.check
        end
      end

      private

      def create_addresses(addresses, db = nil)
        db ||= self.db
        addresses = addresses.flat_map { |add| add.split("@") }
        values = (1..addresses.length).each_slice(2).map { |n, d| "($#{n}, $#{d})" }.join(", ")
        query = "WITH v(name, domain_name) AS (VALUES #{values}) "\
                "INSERT INTO addresses(name, domain_id) "\
                "SELECT v.name, domains.id FROM v INNER JOIN domains ON domains.name = domain_name "\
                "ON CONFLICT DO NOTHING;"
        result = db.exec_params(query, addresses)
        result.check
        result
      end

      def get_or_create_addresses(addresses, db = nil)
        db ||= self.db
        addresses_db = get_addresses(addresses, db)
        addresses = addresses.reject do |address|
          addresses_db&.any? { |add| "#{add["name"]}@#{add["domain_name"]}" == address }
        end
        return addresses_db if addresses.blank?

        create_addresses(addresses, db)
        puts "Created addresses #{addresses.join(", ")}."
        get_addresses(addresses, db).concat(addresses_db || [])
      end

      def get_addresses(addresses, db = nil)
        db ||= self.db
        values = (1..addresses.length).map { |i| "(addresses.name = $#{2 * i - 1} AND domains.name = $#{2 * i})" }
                                      .join(" OR ")
        result = db.exec_params("SELECT addresses.*, domains.name AS domain_name FROM "\
                                "addresses INNER JOIN domains ON domains.id = domain_id WHERE #{values}",
                                addresses.flat_map { |add| add.split("@") })
        result.check

        result.num_tuples.positive? ? result.each.to_a : nil
      end
    end
  end
end
