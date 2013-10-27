require 'open-uri'
module PubliSci
  class Dataset
    extend PubliSci::Interactive

    def self.reader_registry
      @reader_registry ||= {}
    end

    def self.register_reader(extension,klass)
      reader_registry[extension] = klass
    end

    def self.for(object, options={}, ask_on_ambiguous=true)
      if options == false || options == true
        ask_on_ambiguous = options
        options = {}
      end

      if object.is_a? String
        if File.exist? object
          if File.extname(object).size > 0
            extension = File.extname(object)
          elsif File.basename(object)[0] == '.' && File.basename(object).count('.') == 1
            extension = File.basename(object)
          else
            raise "Can't load file #{object}; file type inference not yet implemented"
          end

          if reader_registry.keys.include? extension
            k = reader_registry[extension]
            if k.respond_to? "automatic"
              reader_registry[extension].automatic(object,options,ask_on_ambiguous)
            else
              reader_registry[extension].new.automatic(object,options,ask_on_ambiguous)
            end
          else
            case extension
            when ".RData"
              r_object(object, options, ask_on_ambiguous)
            when /.csv/i
              PubliSci::Readers::CSV.new.automatic(object,nil,options,ask_on_ambiguous)
            when /.arff/i
              PubliSci::Readers::ARFF.new.generate_n3(object)
            else
              # false
              raise "Unkown Extension #{extension}"
            end
          end
        elsif object =~ %r{htt(p|ps)://.+}
          self.for(download(object).path, options, ask_on_ambiguous) || RDF::Statement.new(RDF::URI(object), RDF::URI('http://semanticscience.org/resource/hasValue'), IO.read(download(object).path)).to_s
          # raise res
          # self.for_remote(object)
        else
          raise "Unable to find reader for String '#{object}'"
          # TODO: better handling of missing readers; need this way for raw strings for now
          # false
        end
      elsif object.is_a? Rserve::REXP
        r_object(object, options, ask_on_ambiguous)
      else
        raise "not recognize Ruby objects of this type yet (#{object})"
      end
    end

    def self.download(uri)
      out = Tempfile.new(uri.split('/').last)
      out.write open(uri).read
      out.close
      out
    end

    def self.r_object(object, options={}, ask_on_ambiguous=true)
      if object.is_a? String
        con = Rserve::Connection.new
        vars = con.eval("load('#{File.absolute_path object}')")
        if vars.to_ruby.size > 1 && ask_on_ambiguous
          puts "Which variable? #{vars.to_ruby}"
          var = vars.to_ruby[gets.to_i]
        else
          var = vars.to_ruby[0]
        end

        r_classes = con.eval("class(#{var})").to_ruby

        if r_classes.include? "data.frame"
          df = PubliSci::Readers::Dataframe.new
          unless options[:dimensions] || !ask_on_ambiguous
            dims = con.eval("names(#{var})").to_ruby
            puts "Which dimensions? #{dims}"
            selection = gets.chomp
            if selection.size > 0
              options[:dimensions] = selection.split(',').map(&:to_i).map{|i| dims[i]}
            end
          end
          unless options[:measures] || !ask_on_ambiguous
            meas = con.eval("names(#{var})").to_ruby
            puts "Which measures? #{meas} "
            selection = gets.chomp
            if selection.size > 0
              options[:measures] = selection.split(',').map(&:to_i).map{|i| meas[i]}
            end
          end

          df.generate_n3(con.eval(var),var,options)

        elsif r_classes.include? "cross"
          bc = PubliSci::Readers::RCross.new

          unless options[:measures] || !ask_on_ambiguous
            pheno_names = con.eval("names(#{var}$pheno)").to_ruby
            puts "Which phenotype traits? #{pheno_names}"
            selection = gets.chomp
            if selection.size > 0
              options[:measures] = selection.split(',').map(&:to_i).map{|i| pheno_names[i]}
            end
          end

          base = var
          if ask_on_ambiguous
            puts "Output file base?"
            base = gets.chomp
            base = var unless base.size > 0
          end

          bc.generate_n3(con, var, base, options)

        elsif r_classes.include? "matrix"
          mat = PubliSci::Readers::RMatrix.new

          unless options[:measures] || !ask_on_ambiguous
            puts "Row label"
            rows = gets.chomp
            rows = "row" unless rows.size > 0

            puts "Column label"
            cols = gets.chomp
            cols = "column" unless cols.size > 0

            puts "Entry label"
            vals = gets.chomp
            vals = "value" unless vals.size > 0

            options[:measures] = [cols,rows,vals]
          end

          base = var
          if ask_on_ambiguous
            puts "Output file base?"
            base = gets.chomp
            base = var unless base.size > 0
          end

          mat.generate_n3(con, var, base, options)
        else
          raise "no PubliSci::Readers found for #{r_classes}"
        end

      elsif object.is_a? Rserve::REXP
        if object.attr.payload["class"].payload.first

          df = PubliSci::Readers::Dataframe.new

          var = nil

          if ask_on_ambiguous
            var = interact("Dataset name?",nil)
          end

          unless options[:dimensions] || !ask_on_ambiguous
            dims = object.payload.names
            selection = interact("Which dimensions?","row",dims){|s| puts s; nil}
            options[:dimensions] = selection if selection
          end

          unless options[:measures] || !ask_on_ambiguous
            meas = object.payload.names
            options[:measures] = interact("Which measures?",meas,meas)
          end

          df.generate_n3(object,var,options)
        else
          raise "support for other Rserve objects coming shortly"
        end

      else
        raise "#{object} is not an R object"
      end
    end
  end
end