require "rexml/document"
require "CSV"
require 'bigdecimal'

class Vertex
  attr_accessor :name, :distance, :predecessor, :conversion
  
  def initialize(name)
    @name = name
    @distance = 1024 #infinity for our purposes
    @conversion = BigDecimal.new("1")
    @predecessor = nil
  end
end

class Edge
   attr_accessor :source, :dest, :weight 
   
   def initialize(source, dest, weight)
     @source = source
     @dest = dest
     @weight = weight
   end
end

def bankers_round(value)
  puts"value: #{value.to_f}, #{value.class.name}"
  base = BigDecimal.new(value.truncate.to_s)
  decimal = value - base
  puts "decimal: #{decimal}, #{decimal.class.name}"
  if base % 2 != 0 && decimal >= 0.5
    puts "rounding from #{base} => #{base+1} <---------------------------"
    base += 1
  end
  puts "base: #{base.to_f}, #{base.class.name}"
  base
end

# rate_file = "SAMPLE_RATES.xml"
# trans_file = "SAMPLE_TRANS.csv"

rate_file = "RATES.xml"
trans_file = "TRANS.csv"

product = "DM1182"
target_currency = "USD"



e_to_u = BigDecimal.new("1.3442")*BigDecimal.new("1.0079")*BigDecimal.new("1.0090")
p "#{e_to_u}"

xml= File.read(rate_file)
doc = REXML::Document.new(xml)

vertices = {}
edges = []
doc.elements.each('rates/rate') do |r|
  edges << Edge.new(r.elements["to"].text, r.elements["from"].text, BigDecimal.new(r.elements["conversion"].text))
  vertices[r.elements["to"].text] = Vertex.new(r.elements["to"].text) unless vertices[r.elements["to"].text]
  vertices[r.elements["from"].text] = Vertex.new(r.elements["from"].text) unless vertices[r.elements["from"].text]
end

#Bellman Ford
vertices[target_currency].distance = 0

(vertices.length-1).times do
  edges.each do |e|
    u = vertices[e.source]
    v = vertices[e.dest]
    if u.distance + 1 < v.distance
      v.distance = u.distance + 1
      v.predecessor = u
      v.conversion = u.conversion * e.weight
    end
  end
end

vertices.each do |k,v|
  puts "#{v.name} => #{target_currency} (#{v.conversion.to_f}, #{v.conversion.class.name})"
end

total = BigDecimal.new("0")
CSV.foreach(trans_file) do |row|
  if row[1] == product
    puts "row: #{row}"
    currency = row[2].split[1]
    amount = BigDecimal.new(row[2].split[0])*100
    puts "adding #{amount.to_f}, #{amount.class.name}"
    if target_currency == currency
      total += amount
    else
      puts "#{amount} * #{vertices[currency].conversion} => #{amount * vertices[currency].conversion}"
      to_add = bankers_round(amount * vertices[currency].conversion)
      puts "converted amount: #{to_add}"
      total += to_add
    end
    puts "total value: #{total.to_f}, type: #{total.class.name}"
    puts "---------------------"
  end

end
puts "#{(total/100).to_f}"