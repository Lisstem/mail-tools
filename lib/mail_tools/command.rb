# frozen_string_literal: true

require_relative "command/list"
require_relative "command/setup"
require_relative "command/teardown"
require_relative "command/add"

module MailTools
  module Command
    class << self
      def commands
        @commands ||= init
      end

      def execute(args)
        name = args.shift
        sub_command = args.shift || :default
        if commands[name.to_sym].respond_to? sub_command
          commands[name.to_sym].public_send(sub_command, *args)
        else
          commands[name.to_sym].public_send(:default, sub_command, *args)
        end
      end

      private

      def init
        db = MailTools::DB.connection
        { list: List.new(db), setup: Setup.new(db), teardown: Teardown.new(db), add: Add.new(db) }
      end
    end
  end
end