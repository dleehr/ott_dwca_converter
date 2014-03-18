#!/usr/bin/env ruby

require 'dwc-archive'
require 'csv'
require 'json'
require 'optparse'

SEPARATOR = "\t|\t"

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: convert_taxonomy.rb [options]"
  opts.on('-s', '--source_dir DIR', 'Opentree taxonomy directory') {|v| options[:source_dir] = v}
  opts.on('-d', '--dest FILE.tar.gz', 'Darwin Core Output File') {|v| options[:dest] = v}
end

def convert(source_dir, dest)
  taxonomy_file = File.join(source_dir, 'taxonomy.tsv')
  synonyms_file = File.join(source_dir, 'synonyms.tsv')
  metadata_file = File.join(source_dir, 'about.json')

  print "Building DWC Archive from #{source_dir} as #{dest}"
  dwc_gen = DarwinCore::Generator.new(dest)
  taxonomy = []
  #noinspection RubyLiteralArrayInspection
  taxonomy << [
    'http://rs.tdwg.org/dwc/terms/taxonID', # uid
    'http://rs.tdwg.org/dwc/terms/parentNameUsageID', # parent_uid
    'http://rs.tdwg.org/dwc/terms/scientificName', # name
    'http://rs.tdwg.org/dwc/terms/taxonRank' # rank
  ]
  # also
  #  sourceinfo
  #  uniqname
  #  flags
  CSV.foreach(taxonomy_file, {col_sep: SEPARATOR, headers: true}) do |row|
    hash_row = Hash(row)
    taxonomy << hash_row.values_at('uid','parent_uid','name','rank')
  end
  dwc_gen.add_core(taxonomy,'taxa.txt')

  # Synonyms
  # name	|	uid	|	type	|	uniqname	|
  synonyms = []
  #noinspection RubyLiteralArrayInspection
  synonyms << [
    'http://rs.tdwg.org/dwc/terms/taxonID', # uid
    'http://rs.tdwg.org/dwc/terms/scientificName', # name
    'http://rs.tdwg.org/dwc/terms/taxonomicStatus', # type
    'http://rs.tdwg.org/dwc/terms/taxonRemarks',
  ]
  CSV.foreach(synonyms_file, {col_sep: SEPARATOR, headers: true}) do |row|
    hash_row = Hash(row)
    synonyms << hash_row.values_at('uid','name','type','uniqname')
  end

  dwc_gen.add_extension(synonyms,'synonyms.txt')
  # TODO: Add metadata from JSON
  File.open(metadata_file) do |json_file|
    metadata = JSON.load(json_file)
    puts metadata
  end
  dwc_gen.add_meta_xml
  dwc_gen.pack
end

begin
  optparse.parse!
  mandatory = [:source_dir, :dest]
  missing = mandatory.select{ |param| options[param].nil? }
  if not missing.empty?
    puts optparse
    exit
  end
  convert(options[:source_dir], options[:dest])
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts optparse
  exit
end
