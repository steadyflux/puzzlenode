require "rexml/document"
require "CSV"

class Vertex
  attr_accessor :name, :distance, :predecessor, :conversion
  
  def initialize(name)
    @name = name
    @distance = 1024 #infinity for our purposes
    @conversion = 1
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
  base = (value*100).truncate
  decimal = value*100 - (value*100).truncate
  if base.odd?
    if decimal >= 0.5 
      base += 1
    end
  end
  base
end

# rate_file = "SAMPLE_RATES.xml"
# trans_file = "SAMPLE_TRANS.csv"

rate_file = "RATES.xml"
trans_file = "TRANS.csv"

product = "DM1182"
target_currency = "USD"

xml= File.read(rate_file)
doc = REXML::Document.new(xml)

vertices = {}
edges = []
doc.elements.each('rates/rate') do |r|
  edges << Edge.new(r.elements["to"].text, r.elements["from"].text, r.elements["conversion"].text.to_f)
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

# vertices.each do |k,v|
#   puts "#{v.name} => #{target_currency} (#{v.conversion})"
# end

total = 0
CSV.foreach(trans_file) do |row|
  if row[1] == product
    currency = row[2].split[1]
    amount = row[2].to_f
    if target_currency == currency
      total += amount*100
    else
      # puts "adding #{bankers_round(amount * vertices[currency].conversion)}"
      total += bankers_round(amount * vertices[currency].conversion)
    end
  end
end
puts "#{total/100}"