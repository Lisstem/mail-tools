# frozen_string_literal: true

module MailTools
  module Util
    module Behaviour
      def default_behavior_like(attribute)
        attribute = "@#{attribute}".to_sym

        def_respond_to_missing(attribute)

        define_method :method_missing do |symbol, *args, **hash, &block|
          instance_variable_get(attribute).public_send(symbol, *args, **hash, &block)
        end
      end

      private

      def def_respond_to_missing(attribute)
        define_method :respond_to_missing? do |symbol, *args|
          instance_variable_get(attribute).respond_to?(symbol) ||
            super_method(self.class, :respond_to_missing?)&.bind(self)&.call(symbol, *args)
        end
      end

      def super_method(method, clas)
        clas.ancestors.select { |a| a.instance_methods.include? method }.first&.instance_method(method)
      end
    end
  end
end
