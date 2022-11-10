# frozen_string_literal: true

require "bcrypt"
require "io/console"

module MailTools
  module Command
    module Input
      class << self
        def encrypted_password(password = nil)
          password ||= ask_for_password
          "{BLF-CRYPT}#{BCrypt::Password.create(password)}"
        end

        def ask_for_password
          password = $stdin.getpass("password: ").strip while password.blank?
          raise Error unless password == $stdin.getpass("password (confirm): ").strip

          password
        end
      end
    end
  end
end
