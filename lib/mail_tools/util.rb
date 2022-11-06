module MailTools
  module Util
    private

    def object_apply(object, sym, values: false)
      if object.respond_to? :each_pair
        object.map { |k, v| [k.public_send(sym), object_apply(v, sym, values:)] }.to_h
      elsif object.respond_to? :each
        object.map { |o| object_apply(o, sym, values:) }
      else
        values ? object.public_send(sym) : object
      end
    end
  end
end
