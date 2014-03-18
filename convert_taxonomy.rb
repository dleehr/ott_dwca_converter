require 'dwc-archive'
require 'csv'

NCBI_ASTER = '/Users/dan/Code/reference-taxonomy/t/tax/ncbi_aster/taxonomy.tsv'
OUTPUT_FILE = '/Users/dan/Code/taxonomy.tar.gz'
SEPARATOR = "\t|\t"

def convert(source, dest)
  print "Building DWC Archive from #{source} as #{dest}"
  dwc_gen = DarwinCore::Generator.new(dest)
  taxonomy = []
  #noinspection RubyLiteralArrayInspection
  taxonomy << [
    'http://rs.tdwg.org/dwc/terms/taxonID', # uid
    'http://rs.tdwg.org/dwc/terms/parentNameUsageID', # parent_uid
    'http://rs.tdwg.org/dwc/terms/scientificName', # name
    'http://rs.tdwg.org/dwc/terms/taxonRank' # rank
  ]
  CSV.foreach(source, {col_sep: SEPARATOR, headers: true}) do |row|
    hash_row = Hash(row)
    taxonomy << hash_row.values_at('uid','parent_uid','name','rank')
  end
  dwc_gen.add_core(taxonomy,'taxonomy.txt')

  # Add metadata from JSON

  dwc_gen.add_meta_xml
  dwc_gen.pack
end

convert(NCBI_ASTER,OUTPUT_FILE)