# PubliSci

[![Build Status](https://travis-ci.org/wstrinz/publisci.png?branch=master)](https://travis-ci.org/wstrinz/publisci)

Note: this software is under active development! Until it hits v 1.0.0, the overall API and usage pattern is subject to change.

## Installation

```sh
gem install publisci
```

## Usage

#### DSL

Most of the gem's functions can be accessed through its DSL

```ruby
require 'publisci'
include PubliSci::DSL

# Specify input data
data do
  # use local or remote paths
  source 'https://github.com/wstrinz/publisci/raw/master/spec/csv/bacon.csv'

  # specify datacube properties
  dimension 'producer', 'pricerange'
  measure 'chunkiness'

  # set parser specific options
  option 'label_column', 'producer'
end

# Describe dataset
metadata do
  dataset 'bacon'
  title 'Bacon dataset'
  creator 'Will Strinz'
  description 'some data about bacon'
  date '1-10-2010'
end

# Send output to an RDF::Repository
#  can also use 'generate_n3' to output a turtle string
repo = to_repository

# run SPARQL queries on the dataset
PubliSci::QueryHelper.execute('select * where {?s ?p ?o} limit 5', repo)

# export in other formats
PubliSci::Writers::ARFF.new.from_store(repo)
```


#### Gem executable

Running the gem using the `publisci` executable will attempt to find and run
an triplifier for your input.

For example, the following

```sh
publisci https://github.com/wstrinz/publisci/raw/master/spec/csv/bacon.csv
```

Is equivalent to the DSL code

```ruby
require 'publisci'
include PubliSci::DSL

data do
  source 'https://github.com/wstrinz/publisci/raw/master/spec/csv/bacon.csv'
end

generate_n3
```

The API doc is online. For more code examples see the test files in
the source tree.

### Custom Parsers

Building a parser simply requires you to implement a `generate_n3` method, either at the class or instance level. Then register it using `Publisci::Dataset.register_reader(extension, class)` using your reader's preferred file extension and its class. This way, if you call the `Dataset.for` method on a file with the given extension it will use your reader class.

Including or extending the `Publisci::Readers::Base` will give you access to many helpful methods for creating a triplifying your data. There is a post on the [project blog](http://gsocsemantic.wordpress.com/2013/08/31/parsing-with-publisci-how-to-get-your-data-into-the-semantic-web/) with further details about how to design and implement a parser.

The interface is in the process of being more rigdly defined to separate parsing, generation, and output, and it is advisable to you make your parsing code as stateless as possible for better handling of large inputs. Pull requests with parsers for new formats are greatly appreciated however!

## Project home page

Information on the source tree, documentation, examples, issues and
how to contribute, see

  http://github.com/wstrinz/publisci

The BioRuby community is on IRC server: irc.freenode.org, channel: #bioruby.

## Cite

If you use this software, please cite

* [The Ruby Science Foundation. 2013. SciRuby: Tools for scientific computing in Ruby. http://sciruby.com.](http://sciruby.com)

and one of

* [BioRuby: bioinformatics software for the Ruby programming language](http://dx.doi.org/10.1093/bioinformatics/btq475)
* [Biogem: an effective tool-based approach for scaling up open source software development in bioinformatics](http://dx.doi.org/10.1093/bioinformatics/bts080)

## Biogems.info

This Biogem is published at (http://biogems.info/index.html#publisci)

## Copyright

Copyright (c) 2013 wstrinz. See LICENSE.txt for further details.

