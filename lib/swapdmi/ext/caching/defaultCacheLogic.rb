

module SwapDmi
module DefaultCacheLogic
	
	#define these for testing purposes,
	# normally won't need to use them
	def self.internal()
		Rails.logger.error("WARNING! in DefaultCacheLogic class.internal")
		@internal = {:cacheBody => {}, :cacheDate => {}} if @internal.nil?
		@internal
	end
	def internal
		Rails.logger.error("WARNING! in DefaultCacheLogic instance.internal")
		SwapDmi::DefaultCacheLogic.internal
	end

	def self.configureCacheKeySchema(schema)
		schema.defineMainKeyClean(&SwapDmi::DefaultCacheLogic::CacheKeyClean)
		schema.defineTagClean(&SwapDmi::DefaultCacheLogic::CacheKeyClean)
		
		schema.defineMainKeyCompare(&SwapDmi::DefaultCacheLogic::CacheKeyCompare)
		schema.defineTagCompare(&SwapDmi::DefaultCacheLogic::CacheKeyCompare)
		
		schema.defineMainKeyValid(&SwapDmi::DefaultCacheLogic::CacheKeyValidValue)
		schema.defineTagValid(&SwapDmi::DefaultCacheLogic::CacheKeyValidValue)
	end

	def self.configureCache(cache)
		Rails.logger.debug("!!!ConfigDefault #{cache.id}")
		cid = cache.id
		cache.defineReady do
			Rails.logger.debug("!!!Ready #{cid}")
			self.instance_exec(&SwapDmi::DefaultCacheLogic::CacheReady)
		end
			 
		cache.defineSave(&SwapDmi::DefaultCacheLogic::CacheSave)
		cache.defineValidId(&SwapDmi::DefaultCacheLogic::CacheKeyValidId)
		cache.defineGetMany(&SwapDmi::DefaultCacheLogic::CacheGetMany)
		cache.defineGetOne(&SwapDmi::DefaultCacheLogic::CacheGetOne)
		cache.defineHas(&SwapDmi::DefaultCacheLogic::CacheHasKey)
		cache.defineEviction(&SwapDmi::DefaultCacheLogic::CacheEvict)
	end
	
	CacheKeyValidValue = Proc.new do |ki|
		if SwapDmi::CacheKey.wildcard?(ki)
			false
		elsif ki.nil? 
			false
		else 
			true
		end
	end
	
	CacheKeyValidId = Proc.new do |k|
		case k
			when SwapDmi::CacheKey then k.isValid?
			else SwapDmi::DefaultCacheLogic::CacheKeyValidValue.call(k) 
		end
	end
	
	CacheKeyClean = Proc.new do |ki|
		case ki
			when Numeric then ki
			else ki.to_s.downcase.strip.to_sym 
		end
	end
	
	CacheKeyCompare = Proc.new do |ka,kb|
		conds = [
			Proc.new {|a,b| a == b},
			Proc.new {|a,b| a.to_s =~ /#{b.to_s}/i},
			Proc.new {|a,b| b.to_s =~ /#{a.to_s}/i},
			Proc.new {|a,b| a == SwapDmi::CacheKey::Wildcard},
			Proc.new {|a,b| b == SwapDmi::CacheKey::Wildcard}, 
		]
	
		matches = conds.map do |cond| 
			begin
				cond.call(ka,kb)
			rescue
				false
			end
		end
		matches.include?(true)
	end
	
	CacheSave = Proc.new do |k, data|
		Rails.logger.debug( "!!!Save: #{self.id}:")
		Rails.logger.debug("\tCB:\n\t#{internal[:cacheBody].keys.join("\n\t")}")
		
		internal[:cacheBody][k] = data
		internal[:cacheDate][k] = Time.now
	end
	
	CacheHasKey = Proc.new do |k|
		Rails.logger.debug("!!!Has call: #{SwapDmi::CacheKey.wildcard?(k)}")
		if internal[:cacheBody].empty?
			Rails.logger.debug("!!!Has short circut empy")
			false
		elsif SwapDmi::CacheKey.wildcard?(k)
			Rails.logger.debug("!!!Has short circut has *")
			true
		else
			!self.getOne(k).nil?
		end
	end
	
	CacheEvict = Proc.new do |ks|
		now = Time.now
		threshold = self.config[:evictTime]
		toSkip = []
		
		unless threshold.nil?
		Rails.logger.debug("!!!CacheEvict attempt evict") 
		unless internal[:cacheBody].empty?
		ks.each do |k| 
			isWildcard = SwapDmi::CacheKey.wildcard?(k)
			Rails.logger.debug("!!!CacheEvict wildcard mode") if isWildcard
			isKyFull = k.kind_of?(SwapDmi::CacheKey)
		
			internal[:cacheBody].keys.each do |xk|
				next if toSkip.include?(xk)
				time = internal[:cacheDate][xk]
				Rails.logger.debug("!!!CacheEvict #{threshold} <=> #{now - time}")
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
					SwapDmi::DefaultCacheLogic::CacheKeyCompare.call(k,xk)
				end
				
				internal[:cacheBody].delete(xk) if match
			end 
			
			Rails.logger.debug("!!!CacheEvict short circut *") if isWildcard
			break if isWildcard
		end end end
	end
	
	CacheGetOne = Proc.new do |k|
		if SwapDmi::CacheKey.wildcard?(k)
			all = self.getMany(k)
			all.empty? ? nil : all[ all.keys[0] ]
		else 
			self.getMany(k)[k]
		end
	end
	
	CacheGetMany = Proc.new do |ks|
		results = {}
		
		unless internal[:cacheBody].empty?
		ks.each do |k|
			isWildcard = SwapDmi::CacheKey.wildcard?(k)
			Rails.logger.debug("!!!CacheGetMany wildcard mode") if isWildcard
			isKyFull = k.kind_of?(SwapDmi::CacheKey)
			
			internal[:cacheBody].keys.each do |xk|
				next if results.keys.include?(xk)
				isXkyFull = xk.kind_of?(SwapDmi::CacheKey)
				
				match = if isWildcard
					true
				elsif isKyFull
					k =~ xk
				elsif isXkyFull
					xk.matchMainKey(k)	
				else
					SwapDmi::DefaultCacheLogic::CacheKeyCompare.call(k,xk)
				end
				
				Rails.logger.debug("!!!CacheGetMany #{k} <=> #{xk} = #{match}")
				results[xk] = internal[:cacheBody][xk] if match
			end
			Rails.logger.debug("!!!CacheGetMany short circut has *") if isWildcard
			break if isWildcard
		end end
			
		results
	end
	
	CacheReady = Proc.new do
		Rails.logger.debug( "!!!Ready: #{self.id}:")
		self.defineInternalData(:cacheBody, {})
		self.defineInternalData(:cacheDate, {})
	end
	
end end
	
module SwapDmi
	
	DefaultCacheKeySchema = SwapDmi::CacheKeySchema.new(:default)
  SwapDmi::DefaultCacheLogic.configureCacheKeySchema(DefaultCacheKeySchema)
  
	DefaultCache = SwapDmi::Cache.new(:default)
	SwapDmi::DefaultCacheLogic.configureCache(DefaultCache)
	
end
