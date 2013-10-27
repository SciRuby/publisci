require_relative '../lib/publisci.rb'

#sparql = SPARQL::Client.new("#{repo.uri}/sparql/").query(qry)

class MafQuery
  RESTRICTIONS = {
    patient: '<http://onto.strinz.me/properties/patient_id>',
    sample: '<http://onto.strinz.me/properties/sample_id>',
    gene: '<http://onto.strinz.me/properties/Hugo_Symbol>',
  }

    def to_por(solution)
      if solution.is_a?(Fixnum) or solution.is_a?(String) or solution.is_a?(Symbol)
        solution
      elsif solution.is_a? RDF::Query::Solutions
        solution.map{|sol|
          if sol.bindings.size == 1
            to_por(sol.bindings.first.last)
          else
            Hash(solution.bindings.map{|bind,result| [bind,to_por(result)]})
          end
        }
      elsif solution.is_a? RDF::Query::Solution
        if solution.bindings.size == 1
          to_por(solution.bindings.first.last)
        else
          solution.bindings.map{|bind,result| [bind,to_por(result)] }
        end
      elsif solution.is_a? Array
        if solution.size == 1
          to_por(solution.first)
        else
          solution.map{|sol| to_por(sol)}
        end
      else
        if solution.is_a? RDF::Literal
          solution.object
        elsif solution.is_a? RDF::URI
          solution.to_s
        else
          puts "don't recognzize #{solution.class}"
          solution.to_s
        end
      end
    end

    def generate_data
    	generator = PubliSci::Readers::MAF
    	in_file = 'resources/maf_example.maf'
    	f = Tempfile.new('graph')
    	f.close
    	generator.generate_n3(in_file, {output: :file, output_base: f.path})
    	repo = RDF::Repository.load(f.path+'.ttl')
      File.delete(f.path+'.ttl')
    	f.unlink
      repo
    end

    def select_patient_count(repo,patient_id="A8-A08G")
      qry = IO.read('resources/queries/patient.rq')
      qry = qry.gsub('%{patient}',patient_id)
      SPARQL.execute(qry,repo).first[:barcodes]
    end

    def patients(repo)
      qry = IO.read('resources/queries/patient_list.rq')
      SPARQL.execute(qry,repo) #.map(&:id).map(&:to_s)
    end

    def select_patient_genes(repo,patient_id="A8-A08G")
      qry = IO.read('resources/queries/gene.rq')
      qry = qry.gsub('%{patient}',patient_id)
      SPARQL.execute(qry,repo)
    end

    def select_property(repo,property=["Hugo_Symbol"],restrictions={})
    	# qry = IO.read('resources/queries/maf_column.rq').gsub('%{patient}',patient_id).gsub('%{column}',property)
      property = Array(property)
      selects = property
      property = property.map{|prop|
        RESTRICTIONS[prop.to_sym] || "<http://onto.strinz.me/properties/#{prop}>"
      }

      targets = ""
      property.each_with_index{|p,i|
        targets << "\n  #{p} ?#{selects[i]} ;"
      }

      str = ""
      restrictions.each{|restrict,value|
        prop = RESTRICTIONS[restrict.to_sym] || "<http://onto.strinz.me/properties/#{restrict}>"
        if value.is_a? String
          if RDF::Resource(value).valid?
            if(value[/http:\/\//])
              value = RDF::Resource(value).to_base
            end
          else
            value = '"' + value + '"'
          end
        end
        str << "\n  #{prop} #{value} ;"
      }


      qry = <<-EOF
      PREFIX qb:   <http://purl.org/linked-data/cube#>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX sio: <http://semanticscience.org/resource/>

      SELECT DISTINCT ?#{selects.join(" ?")} WHERE {
        ?obs a qb:Observation;
        #{str}
        #{targets}
        .
      }
      EOF

      results = SPARQL.execute(qry,repo)
      # results = results.map{ |solution|
      #   solution.bindings.map{ |bind,result| [bind, result]}

      #         # .map(&:column).map{|val|
      #   # if val.is_a?(RDF::URI) and val.to_s["node"]
      #   #   node_value(repo,val)
      #   # else
      #   #   val
      #   # end

      # }.flatten

      if results.size == 1
        results.first
      else
        results
      end
    end

    def node_value(repo,uri)
      qry = "SELECT DISTINCT ?p ?o where { <#{uri.to_s}> ?p ?o}"
      SPARQL.execute(qry,repo).map{|sol|
        if sol[:p].to_s == "http://semanticscience.org/resource/SIO_000300"
          sol[:o]
        elsif sol[:p].to_s == "http://semanticscience.org/resource/SIO_000008"
          qry = "SELECT DISTINCT ?p ?o where { <#{sol[:o].to_s}> ?p ?o}"
          SPARQL.execute(qry,repo).select{|sol| sol[:p].to_s == "http://semanticscience.org/resource/SIO_000300"}.first[:o]
        elsif sol[:p].to_s != "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"
          sol[:o]
        end
      }.reject{|sol| sol == nil}
    end

    def official_symbol(hugo_symbol)
      qry = <<-EOF

      SELECT distinct ?official where {
       {?hgnc <http://bio2rdf.org/hgnc_vocabulary:approved_symbol> "#{hugo_symbol}"}
       UNION
       {?hgnc <http://bio2rdf.org/hgnc_vocabulary:synonym> "#{hugo_symbol}"}

       ?hgnc <http://bio2rdf.org/hgnc_vocabulary:approved_symbol> ?official
      }

      EOF

      sparql = SPARQL::Client.new("http://cu.hgnc.bio2rdf.org/sparql")
      sparql.query(qry).map(&:official).first.to_s
    end

    def gene_length(hugo_symbol)
      hugo_symbol = official_symbol(hugo_symbol.split('/').last)
      qry = IO.read('resources/queries/hugo_to_ensembl.rq').gsub('%{hugo_symbol}',hugo_symbol)
      sparql = SPARQL::Client.new("http://cu.hgnc.bio2rdf.org/sparql")
      sol = sparql.query(qry)

      if sol.size == 0
        raise "No Ensembl entry found for #{hugo_symbol}"
      else
        ensemble_id = sol.map(&:ensembl).first.to_s.split(':').last
      end

      url = URI.parse('http://beta.rest.ensembl.org/')
      http = Net::HTTP.new(url.host, url.port)
      request = Net::HTTP::Get.new('/lookup/id/' + ensemble_id + '?format=full', {'Content-Type' => 'application/json'})
      response = http.request(request)

      if response.code != "200"
        raise "Invalid response: #{response.code}"
      else
        js = JSON.parse(response.body)
        js['end'] - js['start']
      end
    end

    def derive_gene_lengths

    end

    def patient_info(id,repo)
      symbols = Array(to_por(select_property(repo,"Hugo_Symbol",patient: id)))
      # patient_id = select_property(repo,"patient_id",patient: id).to_s
      patient = {patient_id: id, mutation_count: symbols.size, mutations:[]}

      symbols.each{|sym| patient[:mutations] << {symbol: sym, length: gene_length(sym)}}
      patient
    end

    def gene_info(hugo_symbol,repo)
      qry = IO.read('resources/queries/patients_with_mutation.rq').gsub('%{hugo_symbol}',hugo_symbol)
      sols = SPARQL.execute(qry,repo)
      patient_count = sols.size
      {mutations: patient_count, gene_length: gene_length(hugo_symbol), patients: sols.map(&:patient_id).map(&:to_s)}

      # symbols = select_property(repo,"Hugo_Symbol",id).map(&:to_s)
      # patient_id = select_property(repo,"patient_id",id).first.to_s
      # patient = {patient_id: patient_id, mutation_count: symbols.size, mutations:[]}

      # symbols.each{|sym| patient[:mutations] << {symbol: sym, length: gene_length(sym)}}
      # patient
    end
end



describe MafQuery do
	before(:all) do
    @maf = MafQuery.new
		@repo = @maf.generate_data
	end

  describe "query genes" do
    it { @maf.select_patient_genes(@repo,"BH-A0HP").size.should > 0 }
  end

  describe "query number of entries" do
    it { @maf.select_patient_count(@repo,"BH-A0HP").should > 0 }
  end


  describe ".patients" do
    it "retrieves a list of patients" do
      @maf.to_por(@maf.patients(@repo)).first.should == "E9-A22B"
    end
  end

  describe ".select_property" do
  	it { @maf.to_por(@maf.select_property(@repo,"Hugo_Symbol", patient: "BH-A0HP")).should == "http://identifiers.org/hgnc.symbol/A1CF" }
    it { @maf.select_property(@repo,"Entrez_Gene_Id",patient: "BH-A0HP")[:Entrez_Gene_Id].to_s.should == 'http://identifiers.org/ncbigene/29974' }
    it { @maf.select_property(@repo,"Center",patient: "BH-A0HP")[:Center].to_s.should == "genome.wustl.edu" }
    it { @maf.select_property(@repo,"NCBI_Build",patient: "BH-A0HP")[:NCBI_Build].to_i.should == 37 }

    context "extra parsed properties" do
      it { @maf.select_property(@repo,"sample_id",patient: "BH-A0HP")[:sample_id].should == "01A-12D-A099-09" }
      it { @maf.select_property(@repo,"patient_id",patient: "BH-A0HP")[:patient_id].should ==  "BH-A0HP" }
    end

    context "multiple restrictions" do
      it { @maf.select_property(@repo,"Entrez_Gene_Id",patient: "BH-A0HP", :Chromosome => 10)[:Entrez_Gene_Id].to_s.should == 'http://identifiers.org/ncbigene/29974' }
      it { @maf.select_property(@repo,"Entrez_Gene_Id",patient: "BH-A0HP", :Chromosome => 2).should == [] }
    end

    context "multiple selections" do
      it { @maf.select_property(@repo,['Hugo_Symbol', 'Entrez_Gene_Id'],patient: "BH-A0HP")[:Entrez_Gene_Id].to_s.should == 'http://identifiers.org/ncbigene/29974' }
      it { @maf.select_property(@repo,['Hugo_Symbol', 'Entrez_Gene_Id'],patient: "BH-A0HP")[:Hugo_Symbol].to_s.should == 'http://identifiers.org/hgnc.symbol/A1CF' }

    end

  	context "non-existant properties" do
  		it { @maf.select_property(@repo,"Chunkiness",patient: "BH-A0HP").should == [] }
  	end
  end

  context "remote service calls", no_travis: true do
    describe ".gene_length" do
      it { @maf.gene_length('A2BP1').should == 1694245 }
    end

    # describe ".official_symbol" do
    #   it { @maf.official_symbol('A2BP1').should == 'RBFOX1' }
    # end

    describe ".gene_info" do
      it 'collects the number of mutations and gene lengths for each mutation' do
        gene = @maf.gene_info('A1BG',@repo)
        gene[:mutations].should == 2
        gene[:gene_length].should == 8321
        gene[:patients].first.should == "E9-A22B"
      end
    end

    describe ".patient_info" do
      it 'collects the number of patients with a mutation in a gene and its length' do
        patient = @maf.patient_info('BH-A0HP',@repo)
        patient[:mutation_count].should == 1
        patient[:mutations].first[:length].should == 79113
        patient[:mutations].first[:symbol].should == 'http://identifiers.org/hgnc.symbol/A1CF'
      end
    end
  end
end

class QueryScript
  def initialize(repo=nil)
    @__maf = MafQuery.new
    unless repo
      @__repo = @__maf.generate_data
    else
      @__repo = repo
    end
  end

  def select(operation,*args)
    if @__maf.methods.include?(:"select_#{operation}")
      @__maf.to_por(@__maf.send(:"select_#{operation}",@__repo,*args))
    else
      @__maf.to_por(@__maf.select_property(@__repo,operation,*args))
    end
  end

  def gene_length(gene)
    @__maf.to_por(@__maf.gene_length(gene))
  end

  def report_for(type, id)
    @__maf.send(:"#{type}_info",id, @__repo)
  end
end

describe QueryScript do
  describe ".select" do
    before(:all){
      @ev = QueryScript.new
    }

    it { @ev.select('patient_count', "BH-A0HP").should > 0 }

    context "with instance_eval" do
      it { @ev.instance_eval("select 'patient_count', patient: 'BH-A0HP'").should > 0 }
      it { @ev.instance_eval("select 'Hugo_Symbol', patient: 'BH-A0HP'").should == 'http://identifiers.org/hgnc.symbol/A1CF' }
      it { @ev.instance_eval("select 'Chromosome', patient: 'BH-A0HP'").is_a?(Fixnum).should be true }
      it { @ev.instance_eval("report_for 'patient', 'BH-A0HP'").is_a?(Hash).should be true }
    end
  end
end