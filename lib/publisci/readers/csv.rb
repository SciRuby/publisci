module PubliSci
	module Readers
		class CSV
      include Base
      def automatic(file=nil,dataset_name=nil,options={},interactive=true)
        #to do
        # puts "f #{file} \n ds #{dataset_name} opts #{options}"

        unless file || !interactive
          puts "Input file?"
          file = gets.chomp
        end

        raise "CSV reader needs an input file" unless file && file.size > 0


        unless dataset_name
          if interactive
            dataset_name = interact("Dataset name?","#{File.basename(file).split('.').first}"){|sel| File.basename(file).split('.').first }
          else
            dataset_name = File.basename(file).split('.').first
          end
        end


        categories = ::CSV.read(file)[0]


        unless options[:dimensions] || !interactive
          options[:dimensions] = Array(interact("Dimensions?",categories[0],categories))
        end

        unless options[:measures] || !interactive
          meas = categories - (options[:dimensions] || [categories[0]])
          selection = interact("Measures?",meas,meas){|s| nil}
          options[:measures] = Array(selection) unless selection == nil
        end

        generate_n3(file,dataset_name,options)
      end

			def generate_n3(file, dataset_name, options={})
				@data = ::CSV.read(file)
				@options = options
				generate(measures, dimensions, codes, observation_data, observation_labels, dataset_name, options)
			end

			def dimensions
				@options[:dimensions] || [@data[0][0]]
			end

			def codes
				@options[:codes] || dimensions()
			end

			def measures
				@options[:measures] || @data[0] - dimensions()
			end

			def observation_labels
				if @options[:label_column]
					tmp = @data.dup
					tmp.shift
					tmp.map{|row|
						row[@options[:label_column]]
					}
				else
					(1..@data.size - 1).to_a
				end
			end

			def observation_data
				obs = {}
				@data[0].map{|label|
					obs[label] = []
				}
				tmp = @data.dup
				tmp.shift

				tmp.map{|row|
					row.each_with_index{|entry,i|
						obs[@data[0][i]] << entry
					}
				}
				obs
			end
		end
	end
end