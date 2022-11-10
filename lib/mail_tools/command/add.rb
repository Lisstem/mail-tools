# frozen_string_literal: true

require "bcrypt"
require "io/console"

require_relative "base"

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
      
      def user(name, address, password = nil)
        password ||= input_password
        password = "{BLF-CRYPT}#{BCrypt::Password.create(password)}"
        query = "INSERT INTO users(name, password, address_id) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING;"
        db.transaction do |conn|
          address = get_or_create_address(address, conn)
          result = conn.exec_params(query, [name, password, address["id"]])
          result.check
        end
      end

      def aliases(source, destionation)
        
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
      
      def input_password
        password = $stdin.getpass("password: ").strip while password.blank?
        raise Error unless password == $stdin.getpass("password (confirm): ").strip

        password
      end

      def get_or_create_address(address, db = nil)
        db ||= self.db
        address_db = get_address(address, db)
        unless address_db
          create_addresses([address], db)
          address_db = get_address(address, db)
          puts "Created address #{address.inspect}."
        end
        address_db
      end

      def get_address(address, db = nil)
        db ||= self.db
        result = db.exec_params("SELECT addresses.* FROM addresses INNER JOIN domains ON domains.id = domain_id "\
                                "WHERE addresses.name = $1 AND domains.name = $2", address.split("@"))
        result.check

        result.num_tuples.positive? ? result[0] : nil
      end
    end
  end
end
