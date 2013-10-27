module PubliSci
  module Readers
    module Base
      include PubliSci::Query
      include PubliSci::RDFParser
      include PubliSci::Analyzer
      include PubliSci::Interactive
      include PubliSci::Dataset::DataCube

      #should be overridden if extra processing/input is required
      def automatic(*args)
        generate_n3(args[0],Hash[*args[1..-2]])
      end

      def generate_n3(*args)
        raise "#{self} does not implement a generate_n3 method!"
      end

      def sio_value(type,value)
        [
          ["a", type],
          ["http://semanticscience.org/resource/SIO_000300",value]
        ]
      end

      def sio_attribute(attribute_type,value,data_type=nil)
        inner = [
          "http://semanticscience.org/resource/SIO_000300",value
        ]
        if data_type
          inner = [["a", data_type], inner]
        end
        
        outer = 
        [
          "http://semanticscience.org/resource/SIO_000008",
            inner
        ]

        if attribute_type
          outer = [["a", attribute_type], outer] 
        end

        # puts "#{outer}"
        outer
      end

      def next_label
        if @__current_label
          @__current_label += 1
        else
          @__current_label = 0
        end
      end
    end
  end
end
