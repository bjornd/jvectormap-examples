# encoding: UTF-8

require 'csv'
require 'json'
require 'digest'
require 'net/http'

class Geocoder
  @@geocode_url = 'http://maps.googleapis.com/maps/api/geocode/json?address=%address%&sensor=false'

  def self.get_coords(address)
    address_hash = Digest::MD5.hexdigest(address)
    if File.exist?('cache/'+address_hash)
      response = File.read('cache/'+address_hash)
    else
      response = Net::HTTP.get(URI.parse(URI.escape(@@geocode_url.sub('%address%', address))));
      File.open('cache/'+address_hash, "w") do |file|
        file.write( response );
      end
    end
    JSON.parse(response)['results'][0]['geometry']['location']
  end
end

metro = {codes: [], coords: [], names: [], population: {}, unemployment: {}}
states = {}

CSV.foreach('population-metro/ACS_09_1YR_B01003_with_ann.csv', col_sep: ",", encoding: "ISO-8859-1") do |row|
  if (row[3].to_i > 1e6 && !row[2].index(', PR'))
    name = row[2].sub(/( Micro Area| Metro Area)$/, '')
    metro[:names] << name
    metro[:codes] << row[0]
    coords = Geocoder.get_coords(name)
    metro[:coords] << [coords["lat"], coords["lng"]]
  end
end

Dir["population-metro/*.csv"].each do |file|
  /ACS_(?<year>\d{2})/ =~ file
  year = '20'+$~[:year]
  metro[:population][year] = []
  CSV.foreach(file, col_sep: ",", encoding: "ISO-8859-1") do |row|
    index = metro[:codes].find_index(row[0])
    if index
      metro[:population][year][index] = row[3].to_i
    end
  end
end

Dir["employment-metro/*.csv"].each do |file|
  /ACS_(?<year>\d{2})/ =~ file
  year = '20'+$~[:year]
  metro[:unemployment][year] = []
  CSV.foreach(file, col_sep: ",", encoding: "ISO-8859-1") do |row|
    index = metro[:codes].find_index(row[0])
    if index
      metro[:unemployment][year][index] = row[9].to_f
    end
  end
end


state_name_to_code = {}
CSV.foreach('us.tsv', col_sep: "\t", encoding: "UTF-8") do |row|
  state_name_to_code[row[1]] = row[0]
end

Dir["employment-states/*.csv"].each do |file|
  /ACS_(?<year>\d{2})/ =~ file
  year = '20'+$~[:year]
  states[year] = {}
  CSV.foreach(file, col_sep: ",", encoding: "ISO-8859-1") do |row|
    if state_name_to_code[row[2]]
      states[year][state_name_to_code[row[2]]] = row[9].to_f
    end
  end
end

File.open("data.json", "w") do |file|
  file.write( {states: states, metro: metro}.to_json );
end
