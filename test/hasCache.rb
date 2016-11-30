
require 'rubygems'
require 'swapdmi'
require 'swapdmi/ext/caching'

$keys = 100
$values = 10

#
def assertTrue(expression)
	throw :assert unless expression
end

def assertFalse(expression)
	throw :assert if expression
end

TestCache = SwapDmi::Cache.new(:test)
SwapDmi::DefaultCacheLogic.configureCache(TestCache)
TestCache.ready

class Test < SwapDmi::DataSource
		
		defineDefaultCaching(:test)
		
		def getCache()
			self.dataCacher
		end
		
		def insert(k,v)
			vs = self.dataCacher[k]
			puts "\t#{k},#{v} => #{vs.nil?}"
			vs = [] if vs.nil?
			vs << v
			self.dataCacher.save(k, vs)
			self
		end
		
		def get(k)
			vs = self.dataCacher[k]
			vs.nil? ? [] : vs
		end
		
end
	
$keys.times do |k|
	puts "\ninserting for #{k}..."
$values.times do |v|
	puts "\t#{v}"
	assertFalse(Test.default.getCache.nil?)
	assertTrue(Test.default.getCache.id == :test)
	
	error = false
	begin
		Test.default.insert(k,v)
	rescue => e
		puts e
		error = true
	end
	assertFalse(error)
end end

puts "\n\n"
puts TestCache.inspect

$keys.times do |k|
	vs = Test.default.get(k)
	puts "#{k} => (#{vs.size}) #{vs.join(',')}"
	assertFalse(vs.nil?)
	assertTrue(vs.size == $values)
end

puts "test done all ok"
