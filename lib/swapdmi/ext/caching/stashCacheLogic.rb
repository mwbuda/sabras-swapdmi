
#
# cache logic implementation which saves data to a 'stash'
#
# much like a cache, stashs can be tied to any persistence/caching solution.
#	the advantages of using a stash in addition to a cache are that stashs are simpler, 
#		allow for transformation data going in/out of the stash, and can be shared across multiple caches
#
# stashs do NOT support multi or wildcard select, check the validity of keys/key schema, or have the concept of an eviction policy
#		they are intended to be used as a delegate for a cache, 
#		handling the last mile integration with whatever solution is actually acting as backing storage while using default
#		semantics for the more advanced caching features; and not on their own or in place of a cache.
#
# If you want to quickly integrate a cache with some unhandled data store, and not deal with some of the more complex bits 
#	of implementing cache behavior, use a cache backed with a stash. Otherwise implement custom cache logic.
#
#

module SwapDmi
module StashCacheLogic
	
	# raised when the something goes awry with interacting with data in the stash
	class StashUsageError < StandardError

  end
	
	# raised when either configuring a Stash in an invalid manner OR when using an incomplete/invalidly configured Stash
  class StashSetupError < StandardError
  	
  end
  
  # raised if attempt to reconfigure a stash after attempting to use it
  class StashReconfigureError < StandardError
  	
  end
	
	class Stash
		extend SwapDmi::HasConfig
		extend SwapDmi::TrackClassHierarchy
		
		def initialize(id = self.class.defaultId)
			self.assignId(id)
		end
		
		def ready()
			return if @readyFlag
			begin
				self.onReady
			rescue SwapDmi::StashCacheLogic::StashSetupError => setupe
				raise setupe
			rescue => e
				raise SwapDmi::StashCacheLogic::StashSetupError.new(e)
			end
			@readyFlag = true
      self
		end
		
		def isReady?()
			@readyFlag
		end
		
		def put(cid, ck, data)
			self.ready
			begin
				self.onPut(cid, ck, data)
			rescue => e
				raise SwapDmi::StashCacheLogic::StashUsageError(e)
			end
			self	
		end
		
		def get(cid, ck)
			self.ready
			begin
				self.onGet(cid, ck)
			rescue => e
				raise SwapDmi::StashCacheLogic::StashUsageError(e)
			end
		end
		
		def remove(cid, ck)
			self.ready
			begin
				self.onRemove(cid, ck)
			rescue => e
				raise SwapDmi::StashCacheLogic::StashUsageError(e)
			end
			self
		end
		
		def summary(cid)
			self.ready
			begin
				res = self.onSummary(cid)
				res.nil? ? {} : res
			rescue => e
				raise SwapDmi::StashCacheLogic::StashUsageError(e)
			end
		end
		
	end
	
	# handles 'stashing' cache data to some (assumed semi/persistent) store
	#
	#
	class ProgrammableStash < Stash
		
		def defineReady(&block)
			raise SwapDmi::StashCacheLogic::StashReconfigureError.new if self.isReady?
			@ready = block
			self
		end
		
		def onReady()
			return if self.isReady?
			{
				'put' => @stashPut,
				'get' => @stashGet,
				'clear' => @clear,
				'summary' => @summary,
				
			}.each do |desc, behavior|
				raise SwapDmi::StashCacheLogic::StashSetupError.new(desc) if behavior.nil?
			end
			
      self.instance_exec(&@ready) unless @ready.nil?
		end
		
		# |cache-id, cache-key, data|
		#
		def definePut(&block)
			raise SwapDmi::StashCacheLogic::StashReconfigureError.new if self.isReady?
			@stashPut = block
			self
		end
		def onPut(cacheId, cacheKey, data)
				self.instance_exec(cacheId, cacheKey, data, &@stashPut)
		end
		
		# |cache-id, cache-key|
		#
		def defineGet(&block)
			raise SwapDmi::StashCacheLogic::StashReconfigureError.new if self.isReady?
			@stashGet = block
			self
		end
		def onGet(cacheId, cacheKey)
			self.instance_exec(cacheId, cacheKey, &@stashGet)
		end
		
		# |cache-id, cache-key|
		#
		def defineRemove(&block)
			raise SwapDmi::StashCacheLogic::StashReconfigureError.new if @readyFlag
			@clear = block
			self
		end
		def onRemove(cacheId, cacheKey)
			self.instance_exec(cacheId, cacheKey, &@clear)
		end
		
		# |cacheId|
		#
		def defineSummary(&block)
			raise SwapDmi::StashCacheLogic::StashReconfigureError.new if @readyFlag
			@summary = block
			self
		end
		#
		# returns a summary of data currently in the stash for indicated cache-id
		#
		#	{cacheKey => timestamp when data put into stash}
		#
		def onSummary(cacheId)
			self.instance_exec(cacheId, &@summary)
		end
		
	end
	
	StashIdConfigKey = :stashId
	
	def self.configureCache(cache, stashId = :default)
		ready = self.createCacheReady(stashId)
		cache.defineReady(&ready)
			 
		cache.defineSave(&SwapDmi::StashCacheLogic::CacheSave)
		cache.defineValidId(&SwapDmi::DefaultCacheKeyLogic::CacheKeyValidId)
		cache.defineGetMany(&SwapDmi::StashCacheLogic::CacheGetMany)
		cache.defineGetOne(&SwapDmi::DefaultCacheLogic::CacheGetOne)
		cache.defineHas(&SwapDmi::StashCacheLogic::CacheHasKey)
		cache.defineEviction(&SwapDmi::StashCacheLogic::CacheEvict)
		
		self
	end
	
	def self.createCacheReady(stashId)
		sid = stashId
		Proc.new do 
			self.defineInternalData(:stash, SwapDmi::StashCacheLogic::Stash[sid])
		end
	end
	
	CacheSave = Proc.new do |k, data|
		internal[:stash].put(self.id, k, data)
	end
	
	CacheGetMany = Proc.new do |ks|
		results = {}
		stash = internal[:stash]
		stashIndex = stash.summary(self.id)
		
		unless stashIndex.empty?
		ks.each do |k|
			isWildcard = SwapDmi::CacheKey.wildcard?(k)
			isKyFull = k.kind_of?(SwapDmi::CacheKey)
			isKyUnique = isKyFull ? k.unique? : SwapDmi::DefaultCacheKeyLogic::CacheKeyUniqueId.call(k)
			
			stashIndex.keys.each do |xk|
				next if results.keys.include?(xk)
				isXkyFull = xk.kind_of?(SwapDmi::CacheKey)
				
				match = if isWildcard
					true
				elsif isKyFull
					k =~ xk
				elsif isXkyFull
					xk.matchMainKey(k)	
				else
					SwapDmi::DefaultCacheKeyLogic::CacheKeyCompare.call(k,xk)
				end
				
				next unless match
				
				now = Time.now
				stashTs = stashIndex[xk]
				stashTs = now - 1 if stashTs.nil?
				
				results[xk] = stash.get(self.id, xk) if match
				break if match && isKyUnique
			end
			break if isWildcard
		end end
			
		results
	end
	
	CacheHasKey = Proc.new do |k|
		if internal[:stash].summary(self.id).empty?
			false
		elsif SwapDmi::CacheKey.wildcard?(k)
			true
		else
			!self.getOne(k).nil?
		end
	end
	
	CacheEvict = Proc.new do |ks|
		now = Time.now
		stash = internal[:stash]
		stashIndex = stash.summary(self.id)
		threshold = self.config[:evictTime]
		toSkip = []
		
		unless threshold.nil?
		unless stashIndex.empty?
		ks.each do |k| 
			isWildcard = SwapDmi::CacheKey.wildcard?(k)
			isKyFull = k.kind_of?(SwapDmi::CacheKey)
			isKyUnique = isKyFull ? k.unique? : SwapDmi::DefaultCacheKeyLogic::CacheKeyUniqueId.call(k)
		
			stashIndex.keys.each do |xk|
				next if toSkip.include?(xk)
				time = stashIndex[xk]
				next if time.nil?
				toSkip << xk if (now - time) < threshold
				next if toSkip.include?(xk)
				 
				isXkyFull = xk.kind_of?(SwapDmi::CacheKey)
				
				match = if isWildcard
					true
				elsif isKyFull
					k =~ xk
				elsif isXkyFull
					xk.matchMainKey(k)	
				else
					SwapDmi::DefaultCacheKeyLogic::CacheKeyCompare.call(k,xk)
				end
				
				stash.remove(self.id, xk) if match
				break if match && isKyUnique
			end 
			
			break if isWildcard
		end end end
	end
	
end end

