require_relative '../../lib/bio-publisci.rb'

describe R2RDF::ORM::DataCube do

  it "should load and save a turtle file without loss of information" do
    ref = IO.read(File.dirname(__FILE__) + '/../turtle/bacon')
    cube = R2RDF::ORM::DataCube.load(ref, {skip_metadata: true, generator_options: {label_column: 0}})
    cube.abbreviate_known(cube.to_n3).should == ref
    # cube.to_n3.should == ref
  end

end