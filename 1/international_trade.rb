require "rexml/document"
require "CSV"

class Vertex
  attr_accessor :name, :distance, :predecessor, :conversion
  
  def initialize(name)
    @name = name
    @distance = 512 #infinity for our purposes
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
  base.to_f/100
end

product = "DM1182"
target_currency = "USD"

xml= File.read("RATES.xml")
doc = REXML::Document.new(xml)

conversion_multiplier = {}
vertices = {}
edges = []
doc.elements.each('rates/rate') do |r|
  edges << Edge.new(r.elements["from"].text, r.elements["to"].text, r.elements["conversion"].text.to_f)
  vertices[r.elements["to"].text] = Vertex.new(r.elements["to"].text) unless vertices[r.elements["to"].text]
  vertices[r.elements["from"].text] = Vertex.new(r.elements["from"].text) unless vertices[r.elements["from"].text]
end

#Bellman Ford using each non-target-currency as a source
vertices.each do |ok, ov|
  if (ok != target_currency)
    vertices.each do |k,v| 
      v.predecessor = nil
      v.distance = 1024
      v.conversion = 1
      if k == ok
        v.distance = 0
      end
    end
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
    #we only care about the target currency
    conversion_multiplier[ok] = vertices[target_currency].conversion
  end
end

total = 0
CSV.foreach("TRANS.csv") do |row|
  if row[1] == product
    currency = row[2].split[1]
    amount = row[2].to_f
    if target_currency == currency
      total += amount
    else
      puts "adding #{bankers_round(amount * conversion_multiplier[currency])}"
      total += bankers_round(amount * conversion_multiplier[currency])
    end
  end
end
puts "Total: #{total}"