module PubliSci
  module Parsers
    module Base
      include Enumerable
      # attr_accessor :dataset_name, :measures, :dimensions, :codes

      def valid?(rec)
        true
      end

      def enum_method
        :each
      end

      def process_record(rec)
        rec
      end

      def each(input)
        input.send(enum_method) do |rec|
          yield process_record(rec) if valid? rec
        end
      end
      alias_method :each_rec, :each
      alias_method :each_record, :each

    end
  end
end