# require_relative '../../lib/r2rdf/data_cube.rb'
# require_relative '../../lib/r2rdf/generators/csv.rb'
require_relative '../../lib/publisci.rb'

# require 'rdf/turtle'
require 'tempfile'

describe PubliSci::Readers::MAF do
  before(:each) do
    @generator = PubliSci::Readers::MAF
    @in_file = 'resources/maf_example.maf'
  end

  describe ".generate_n3" do
    def is_cube(str)

      str[/a qb:Observation/].should_not be nil
      str[/a rdf:Property, qb:DimensionProperty/].should_not be nil
      str[/a rdf:Property, qb:MeasureProperty/].should_not be nil
      str[/a qb:ComponentSpecification/].should_not be nil
    end

    context "print output" do
      before { @str = @generator.generate_n3(@in_file, {output: :print})}
      it { is_cube(@str) }
    end

    context "file output" do
      before {
        f = Tempfile.new('graph')
        f.close
        @generator.generate_n3(@in_file,{output: :file, output_base: f.path})
        @str = IO.read(f.path+'.ttl')
        open('resources/maf_rdf.ttl','w'){|f| f.write @str}
        f.unlink
      }

      it { is_cube(@str) }
    end
  end
end