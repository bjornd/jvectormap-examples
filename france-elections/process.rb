# encoding: UTF-8

require 'csv'
require 'json'

data = {
  year2012: {
    candidate1: 'Hollande',
    candidate2: 'Sarkozy',
    results: {}
  },
  year2007: {
    candidate1: 'Sarkozy',
    candidate2: 'Royal',
    results: {}
  }
}

name_to_code = {}
CSV.foreach('data/fr.tsv', col_sep: "\t", encoding: "UTF-8") do |row|
  name_to_code[row[1]] = row[0]
end

CSV.foreach('data/2012.csv', col_sep: "\t", encoding: "UTF-8") do |row|
  if name_to_code[row[0]]
    data[:year2012][:results][name_to_code[row[0]]] = row[1] > row[2] ? 1 : 2
  end
end

CSV.foreach('data/2007.csv', col_sep: "\t", encoding: "UTF-8") do |row|
  if name_to_code[row[0]]
    data[:year2007][:results][name_to_code[row[0]]] = row[1] > row[2] ? 1 : 2
  end
end

File.open("data.json", "w") do |file|
  file.write( data.to_json );
end
