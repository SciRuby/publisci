module PubliSci
  module Interactive
    #to be called by other classes if user input is required

    #take message, options, defaults. can be passed block to handle default as well
    def interact(message, default, options=nil)
      puts message + " (#{default})\n[#{options}]"
      str = gets.chomp
      if str.size > 0
        if options
          if str.split(',').all?{|s| Integer(s) rescue nil}
            str.split(',').map(&:to_i).map{|i| options[i]}
          else
            str.split(',').each{|s| raise "unkown selection #{s}" unless options.include? s.strip}
            str.split(',').map(&:strip)
          end
        else
          str
        end
      elsif block_given?
        yield str
      else
        default
      end
    end

    # def interactive(options={})
    #   options = defaults.merge(options)
    #   qb = {}

    #   puts "load config from file? [y/N]"
    #   if gets.chomp == "y"
    #     #use yaml or DSL file to configure
    #   else
    #     qb[:dimensions] = dimensions()
    #     qb[:measures] = measures()
    #   end

    #   puts "load data from file? [y/N]"
    #   if gets.chomp == "y"
    #     #attempt to load dataset from file, ask user to resolve problems or ambiguity
    #   else
    #   end
    #   qb
    # end

    # def dimensions
    #   puts "Enter a list of dimensions, separated by commas"
    #   arr = gets.chomp.split(",")
    #   dims = {}

    #   arr.map{|dim|
    #     puts "What is the range of #{dim.chomp.strip}? [:coded]"
    #     type = gets.chomp
    #     type = :coded if type == ":coded" || type == ""
    #     dims[dim.chomp.strip] = {type: type}
    #   }

    #   dims
    # end

    # def measures
    #   puts "Enter a list of measures, separated by commas"
    #   arr = gets.chomp.split(",")
    #   meas = []

    #   arr.map{|m| meas << m.chomp.strip}

    #   meas
    # end
  end
end