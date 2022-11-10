# frozen_string_literal: true

require_relative "command/list"

module MailTools
  module Command
    class << self
      def commands
        @commands ||= init
      end

      def execute(args)
        puts commands.inspect
        name = args.shift
        commands[name.to_sym].public_send(args.shift.to_sym, *args)
      end

      private

      def init
        { list: List.new(MailTools::DB.connection) }
      end
    end
  end
end