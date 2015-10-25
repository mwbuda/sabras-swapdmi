
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

#cache key matching (default setup)

#check cache readying
	#TODO

	#exact match, main key

	#exact match, w/ tags

	#wildcard match, main key

	#wild card match, main key, spec tags

	#wild card match, tags, spec main key

	#raw main key exact match
	assertTrue( 
		SwapDmi::DefaultCacheLogic::CacheKeyCompare.call(:raw, :raw)
	)
	assertFalse( 
		SwapDmi::DefaultCacheLogic::CacheKeyCompare.call(:raw, :wrong)
	)
	assertFalse( 
		SwapDmi::DefaultCacheLogic::CacheKeyCompare.call(:wrong, :raw)
	)

	#raw main key wildcard match
	assertTrue( 
		SwapDmi::DefaultCacheLogic::CacheKeyCompare.call(SwapDmi::CacheKey::Wildcard, :raw)
	)
	assertTrue( 
		SwapDmi::DefaultCacheLogic::CacheKeyCompare.call(:raw, SwapDmi::CacheKey::Wildcard)
	)

	#check valid id
	assertFalse( SwapDmi::CacheKey.wildcard.validId? )
	assertTrue( SwapDmi::CacheKey.new(:key).validId? )
	assertTrue( SwapDmi::CacheKey.new(1).validId? )
	assertTrue( SwapDmi::CacheKey.new('key').validId? )

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
	
#	data in, data out 
	DefaultCache.save(:key0, 0)
	assertTrue(DefaultCache.has?(:key0))
	assertTrue(DefaultCache.getOne(:key0) == 0)
	
	testGetAll = {
		:key1 => 1,
		:key2 => 2,
		:key3 => 3,
		:key4 => 4
	}
	testGetAll.each {|k,v|  DefaultCache.save(k,v) }
	res = DefaultCache.get(*testGetAll.keys)
	testGetAll.each {|k,v| assertTrue(res[k] == v) }

#	eviction (evict time = 0)
	DefaultCache.config[:evictTime] = 0
	toEvict = [:key0] + testGetAll.keys
	res = DefaultCache.get(SwapDmi::CacheKey::Wildcard)
	assertTrue( res.empty? )
	toEvict.each {|k| assertTrue( DefaultCahce[k].nil? )}

# Test is completed - Output stuff
puts 'Caching Test Completed'
