module PubliSci
  module Readers
    class MAF
      extend PubliSci::Readers::Base

      def self.generate_n3(input_file, options={})
        input_file = open(input_file,'r')

        out_base = options[:output_base] || File.basename(input_file,'.*')

        if options[:output] == :print
          output = StringIO.new("")
        else
          output = open "#{out_base}.ttl",'w'
        end

        PubliSci::Generators::MAF.write_structure(input_file, output, options)

        PubliSci::Parsers::MAF.each_record(input_file) do |rec, label|
          PubliSci::Generators::MAF.write(rec, output, label, options)
        end

        output.close

        if options[:output] == :print
          output.string
        else
          output.path
        end
      end
    end
  end
end