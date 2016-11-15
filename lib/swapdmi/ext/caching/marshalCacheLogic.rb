
#
# cache logic implementation which saves state to marshal output file
#
# other than dependency on saved file of marshal output, cache will otherwise
# behave similar to default cache logic
#
#

module SwapDmi
module MarshalCacheLogic
	
	# used to handle marshalling/demarshalling objects
	# 	if you just want plain marshaling, use the default special constructor
	class Marshaling
		
		def self.default()
			#TODO
		end
		
		def renderMarshalId(cacheKey)
			#TODO
		end
		
		def defineSave(&block)
			#TODO
		end
		
		def defineLoad(&block)
			#TODO
		end
		
	end
	
	def self.marshalSave(data, marshalId, cacheKey)
	
	end
	
	def self.marshalLoad(marshalId, cacheKey)
		
	end
	
	def self.configureCache(cache)
		cache.defineReady do
			self.instance_exec(&SwapDmi::MarshalCacheLogic::CacheReady)
		end
			 
		cache.defineSave(&SwapDmi::MarshalCacheLogic::CacheSave)
		cache.defineValidId(&SwapDmi::DefaultCacheKeyLogic::CacheKeyValidId)
		cache.defineGetMany(&SwapDmi::MarshalCacheLogic::CacheGetMany)
		cache.defineGetOne(&SwapDmi::MarshalCacheLogic::CacheGetOne)
		cache.defineHas(&SwapDmi::MarshalCacheLogic::CacheHasKey)
		cache.defineEviction(&SwapDmi::MarshalCacheLogic::CacheEvict)
		
		self
	end
	
	CacheReady = Proc.new do
		self.defineInternalData(:cacheBody, {})
		self.defineInternalData(:cacheDate, {})
	end
	
	CacheSave = nil 
	
	CacheGetMany = nil
	
	CacheGetOne = nil
	
	CacheHasKey = nil
	
	CacheEvict = nil
	
	DoMarshal = nil
	
	DoUnMarshal = nil
	
end end

