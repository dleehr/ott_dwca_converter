require 'dwc-archive'
require 'csv'

NCBI_ASTER = '/Users/dan/Code/reference-taxonomy/t/tax/ncbi_aster/'
OUTPUT_FILE = '/Users/dan/Code/ncbi_aster.tar.gz'
SEPARATOR = "\t|\t"

def convert(source_dir, dest)
  taxonomy_file = source_dir + 'taxonomy.tsv'
  synonyms_file = source_dir + 'synonyms.tsv'
  metadata_file = source_dir + 'about.json'

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
  dwc_gen.add_meta_xml
  dwc_gen.pack
end

convert(NCBI_ASTER,OUTPUT_FILE)