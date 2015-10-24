
require 'rubygems'
require 'swapdmi'
require 'swapdmi/ext/caching'

#
def assertTrue(expression)
	throw :assert unless expression
end

def assertFalse(expression)
	throw :assert if expression
end

#
# check module inclusion
#
puts 'Checking if extension has loaded - Caching Extension'
throw :assertExtension unless SwapDmi.hasExtensions?(:caching)

#check cache readying

#	can't use cache w/ out def save & get
	did_bork = false
	BorkedCache = SwapDmi::Cache.new(:borked)
	begin
		BorkedCache.has?(1)
	rescue SwapDmi::CacheSetupError => e
		did_bork = true
	end
	assertTrue(did_bork)

#	ready cache, ensure can't reconfigure
	TestCantReconfigCache = SwapDmi::Cache.new(:testCantReconfig)
	SwapDmi::DefaultCacheLogic.configure(TestCantReconfigCache)
	TestCantReconfigCache.ready
	
	did_bork = false
	begin
		TestCantReconfigCache.defineHas {|k| true}
	rescue SwapDmi::CacheReconfigureError => e
		did_bork = true
	end
	assertTrue(did_bork)

#check the default cache logic

	DefaultCache = SwapDmi::Cache.default
	DefaultCache.defineEvictWhen(:all)
	
#	cache key matching
	#TODO
	
#	data in, data out 
	#TODO

#	eviction (evict time = 0)
	DefaultCache.config[:evictTime] = 0
	#TODO

# Test is completed - Output stuff
puts 'Caching Test Completed'
