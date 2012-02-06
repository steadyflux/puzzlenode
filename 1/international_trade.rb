require "rexml/document"
require "CSV"

product = "DM1182"
target_currency = "USD"

xml= File.read("RATES.xml")
doc = REXML::Document.new(xml)
all_rates = Hash.new { |hash, key| hash[key] = [] }
doc.elements.each('rates/rate') do |r|
  all_rates[r.elements["to"].text] << { r.elements["from"].text => r.elements["conversion"].text}
end

conversions = {}
all_rates[target_currency].each { |conversion|
  conversions[conversion.keys.first] = conversion[conversion.keys.first]
  puts "conversions #{conversions}"
}
all_rates.each { |key, value| 
  if key != target_currency
    puts "key: #{key}"
    value.each { |conversion|
      if conversions[conversion.keys.first]
        puts "conversion: #{key} => #{conversion.keys.first}"
      end
      if !conversions[key]
        # still need to get from here to target
        
        # puts "conversion: #{key} => #{conversion.keys.first}"
      end
    }
  end
}

# CSV.foreach("SAMPLE_TRANS.csv") do |row|
#   puts "Amount: #{row[2]}" unless row[1] != product
#   unless target_currency == row[2].split[1]
#     puts "must convert"
#   end
# end