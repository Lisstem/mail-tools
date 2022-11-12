# frozen_string_literal: true

module MailTools
  module Command
    class Base
      def initialize(db)
        raise Error unless db

        @db = db
      end
  
      protected
  
      def db
        @db.connection
      end

      def display_result(result)
        result.check
        format = lengths(result).map { |l| " %-#{l}s " }.join("|")
        header = format % result.fields
        puts(header)
        puts("-" * header.length)
        result.each_row { |row| puts(format % row) }
      end

      def lengths(result, header: true)
        values = header ? result.fields.map(&:length) : Array.new(result.nfields, 0)
        result.each_row do |row|
          (0...result.nfields).each do |i|
            next if values[i] >= row[i].length

            values[i] = row[i].length
          end
        end
        values
      end
    end
  end
end 
