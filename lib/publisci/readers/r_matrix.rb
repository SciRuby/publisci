module PubliSci
  module Readers
    class RMatrix
      include PubliSci::Dataset::DataCube

      #NOTE; this is pretty much hard coded for Karl's application right now, and doesn't
      # do any dimension or code generation. Since its a set of LOD scores indexed by dimension
      # and marker the usual datacube generator wont work (I think). In the future adding an option
      # to specify this kind of a dataset would probably be useful


      def generate_n3(client, var, outfile_base, options={})
        meas = measures(client,var,options)
        dim = dimensions(client,var,options)
        codes = codes(client,var,options)

        outvar = sanitize([var]).first

        probes_per_file = options[:probes_per_file] || 100
        col_select = "colnames"
        col_select = "names" if options[:type] == :dataframe

        #write structure
        open(outfile_base+'_structure.ttl','w'){|f| f.write structure(client,var,outvar,options)}

        probes=client.eval("#{col_select}(#{var})").to_ruby
        if probes == nil
          client.eval("colnames(#{var})=1:ncol(#{var})")
          probes=client.eval("#{col_select}(#{var})").to_ruby
        end
        markers = rows(client,var,options)

        if options[:print]
          puts prefixes(var,options)
        end

        if options[:output] == :string
          str = prefixes(var,options)
        end

        probes.each_with_index{|probe,i|
          #write prefixes and erase old file on first run
          unless options[:print] || options[:output] == :string
            open(outfile_base+"_#{i/probes_per_file}.ttl",'w'){|f| f.write prefixes(var,options)} if i % probes_per_file == 0
          end
          i+=1
          obs_data = observation_data(client,var,i,markers,options)
          labels = labels_for(client,var,probe)

          # labels = sanitize(labels)
          # return obs_data
          if options[:print]
            observations(meas,dim,codes,obs_data,labels,outvar,options).each{|obs| puts obs}
          end

          if options[:output] == :string
            observations(meas,dim,codes,obs_data,labels,outvar,options).each{|obs| str << obs}
          end

          unless options[:print] || options[:output] == :string
            open(outfile_base+"_#{i/probes_per_file}.ttl",'a'){|f| observations(meas,dim,codes,obs_data,labels,outvar,options).map{|obs| f.write obs}}
            puts "#{i}/#{probes.size}" unless options[:quiet]
          end
        }

        if options[:output] == :string
          str
        end
      end

      def structure(client,var,outvar,options={})
        meas = measures(client,var,options)
        dim = dimensions(client,var,options)
        codes = codes(client,var,options)

        str = prefixes(var, options)
        str << data_structure_definition(meas,[],codes,outvar,options)
        str << dataset(outvar,options)
        component_specifications(meas, dim, codes, var, options).map{ |c| str << c }
        measure_properties(meas,var,options).map{|m| str << m}

        str
      end

      #for now just make everything a measure
      def measures(client, var, options={})
        if options[:measures]
          options[:measures]
        else
          ["probe","marker","value"]
        end
        # measure_properties(measures,var,options)
      end

      def dimensions(client, var, options={})
        # dimension_properties([""],var)
        []
      end

      def codes(client, var, options={})
        []
      end

      def labels_for(connection,var,probe_id,options={})
        row_names = connection.eval("row.names(#{var})")
        # row_names = (1..@rexp.payload.first.to_ruby.size).to_a unless row_names.first
        if row_names == connection.eval('NULL')
          row_names = (1..connection.eval("nrow(#{var})").payload.first).to_a
        else
          row_names = row_names.payload
        end

        labels = (1..(row_names.size)).to_a.map(&:to_s)
        labels = labels.map{|l|
          l.insert(0,probe_id.to_s + "_")
        }

        labels
      end

      def rows(connection,var,options={})
        row_names = connection.eval("row.names(#{var})")
        #hacky solution because rserve client's .to_ruby method doesn't fully work
        if row_names == connection.eval('NULL')
          row_names = (1..connection.eval("nrow(#{var})").payload.first).to_a
        else
          row_names = row_names.payload
        end
        row_names
      end

      def observation_data(client, var, probe_number, row_names, options={})

        data = {}
        # geno_chr = client.eval("#{var}$geno$'#{chr}'")
        # n_individuals = client.eval("#{var}$pheno[[1]]").to_ruby.size
        # entries_per_individual = @rexp.payload["geno"].payload[row_individ].payload["map"].payload.size * @rexp.payload["geno"].payload.names.size
        col_label = "probe"
        row_label = "marker"
        val_label = "value"

        if options[:measures]
          col_label = options[:measures][0] || "probe"
          row_label = options[:measures][1] || "marker"
          val_label = options[:measures][2] || "value"
        end

        data["#{col_label}"] = []
        data["#{row_label}"] = []
        data["#{val_label}"] = []

        # n_individuals.times{|row_individ|
        # puts "#{row_individ}/#{n_individuals}"

        col_select = "colnames"
        col_select = "names" if options[:type] == :dataframe

        if options[:type] == :dataframe
          probe_obj = client.eval("#{var}[[#{probe_number}]]").to_ruby
        else
          probe_obj = client.eval("#{var}[,#{probe_number}]").to_ruby
        end
        # puts probe_obj
        probe_id = client.eval("#{col_select}(#{var})[[#{probe_number}]]").to_ruby
        data["#{col_label}"] = (1..(probe_obj.size)).to_a.fill(probe_id)
        probe_obj.each_with_index{|lod,i|
          data["#{row_label}"] << row_names[i]
          data["#{val_label}"] << lod
        }

        data.map{|k,v| v.flatten!}
        data
      end
    end
  end
end
