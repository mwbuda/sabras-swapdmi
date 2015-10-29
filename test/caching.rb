
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
puts 'test cache key matching'
	
	#exact match, main key
	#TODO

	#exact match, w/ tags
	#TODO

	#wildcard match, main key
	#TODO

	#wild card match, main key, spec tags
	#TODO

	#wild card match, tags, spec main key
	#TODO

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
puts 'test must define save & get on cache'
	
	did_bork = false
	BorkedCache = SwapDmi::Cache.new(:borked)
	begin
		BorkedCache.has?(1)
	rescue SwapDmi::CacheSetupError => e
		did_bork = true
	end
	assertTrue(did_bork)

#	ready cache, ensure can't reconfigure
puts 'test cant reconfigure'

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
puts 'test default cache logic thru proxy'
	
	DefaultCache = SwapDmi::Cache.default
	DefaultCache.defineEvictWhen(:all)
	DefaultCacheProxy = SwapDmi::ProxyObject.new(SwapDmi::Cache, :default)
	
#	data in, data out 
	DefaultCacheProxy.save(:key0, 0)
	assertTrue(DefaultCacheProxy.has?(:key0))
	assertTrue(DefaultCacheProxy.getOne(:key0) == 0)
	
	testGetAll = {
		:key1 => 1,
		:key2 => 2,
		:key3 => 3,
		:key4 => 4
	}
	testGetAll.each {|k,v|  DefaultCacheProxy.save(k,v) }
	res = DefaultCacheProxy.getMany(*testGetAll.keys)
	testGetAll.each {|k,v| assertTrue(res[k] == v) }
	res = res = DefaultCacheProxy.getMany(SwapDmi::CacheKey::Wildcard)
	testGetAll.each {|k,v| assertTrue(res[k] == v) }

	assertTrue( DefaultCacheProxy.has?(SwapDmi::CacheKey::Wildcard) )
	testGetAll.keys.each {|k| assertTrue(DefaultCacheProxy.has?(k) ) }
		
#	eviction (evict time = 0)
	DefaultCacheProxy.config[:evictTime] = 0
	toEvict = [:key0] + testGetAll.keys
	res = DefaultCacheProxy.getMany(SwapDmi::CacheKey::Wildcard)
	assertTrue( res.empty? )
	toEvict.each {|k| assertTrue( DefaultCache[k].nil? )}

# Test is completed - Output stuff
puts 'Caching Test Completed'
