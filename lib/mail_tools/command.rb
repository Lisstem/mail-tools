# frozen_string_literal: true

require "active_support/inflector/methods"

require_relative "command/list"
require_relative "command/setup"
require_relative "command/teardown"
require_relative "command/add"
require_relative "command/password"

module MailTools
  module Command
    class << self
      COMMANDS = %w[List Setup Teardown Add Password].freeze

      def execute(db, args)
        name = ActiveSupport::Inflector.camelize(args.shift)
        raise Error, "Unknown command #{args}." unless COMMANDS.include? name

        command = const_get(name)&.new(db)
        sub_command = args.shift || :default
        if command.respond_to? sub_command
          command.public_send(sub_command, *args)
        else
          command.public_send(:default, sub_command, *args)
        end
      end
    end
  end
end