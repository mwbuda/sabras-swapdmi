module SwapDmi
	SwapDmi.declareExtension(:caching)

	module DefaultCacheLogic

		CacheKeyValidValue = Proc.new do |ki|
			case ki
				when SwapDmi::CacheKey::Wildcard then false
				when nil then false
				else true 
			end
		end
		
		CacheKeyValidId = Proc.new do |k|
			case k
				when SwapDmi::CacheKey then k.isValid?
				else SwapDmi::DefaultCacheLogic::CacheKeyValidValue.call(ki) 
			end
		end
		
		CacheKeyClean = Proc.new do |ki|
			case ki
				when Numeric then ki
				else ki.to_s.downcase.trim.to_sym 
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
		
			matches = conds.map {|cond| cond.call(ka,kb)}
			matches.includes?(true)
		end
		
		CacheSave = Proc.new do |k, data|
			internal[:cacheBody][k] = data
			internal[:cacheDate][k] = Time.now
		end
		
		CacheEvict = Proc.new do |ks|
			now = Time.now
			threshold = self.config[:evictTime]
			toSkip = []
			unless threshold.nil?
			ks.each do |k| 
				isKyFull = k.kind_of?(SwapDmi::CacheKey)
			
				internal[:cacheBody].keys.each do |xk|
					next if toSkip.include?(xk)
					
					time = internal[:cacheDate][xk]
					if (now - time) < threshold
						toSkip << xk
						next
					end
					 
					isXkyFull = xk.kind_of?(SwapDmi::CacheKey)
					
					match = if isKyFull
						k =~ xk
					elsif isXkyFull
						xk.matchMainKey(k)	
					else
						SwapDmi::DefaultCacheLogic::CacheKeyCompare.call(k,xk)
					end
					
					internal[:cacheBody].remove(xk) if match
				end 
			end end
		end
		
		CacheGet = Proc.new do |ks|
			results = []
			ks.each do |k|
				isKyFull = k.kind_of?(SwapDmi::CacheKey)
				
				internal[:cacheBody].keys.each do |xk|
					next if results.include?(xk)
					isXkyFull = xk.kind_of?(SwapDmi::CacheKey)
					
					match = if isKyFull
						k =~ xk
					elsif isXkyFull
						xk.matchMainKey(k)	
					else
						SwapDmi::DefaultCacheLogic::CacheKeyCompare.call(k,xk)
					end
					
					results << xk if match
				end
			end
				
			results.map {|k| internal[:cacheBody][k] }
		end
		
		CacheReady = Proc.new do
			self.defineInternalData(:cacheBody, {})
			self.defineInternalData(:cacheDate, {})
		end
  	end
  
  # this class is used along with CacheKey for custom
  #		match/keying semantics w/i a cache.
  class CacheKeySchema
	extend TrackClassHierarchy
	
	def initialize(id)
		self.assignId(id)
		
		@mainKeyClean = SwapDmi::DefaultCacheLogic::CacheKeyClean
		@tagClean = SwapDmi::DefaultCacheLogic::CacheKeyClean
		
		@mainKeyCompare = SwapDmi::DefaultCacheLogic::CacheKeyCompare
		@tagCompare = SwapDmi::DefaultCacheLogic::CacheKeyCompare
		
		@mainKeyValid = SwapDmi::DefaultCacheLogic::CacheKeyValidValue
		@tagValid = SwapDmi::DefaultCacheLogic::CacheKeyValidValue
	end
	
	def defineMainKeyClean(&block)
		@mainKeyClean = block
		self
	end
	def defineMainKeyCompare(&block)
		@mainKeyCompare = block
		self
	end
	def defineMainKeyValid(&block)
		@mainKeyValid = block
		self
	end
	
	def defineTagClean(&block)
		@tagClean = block
		self
	end
	def defineTagCompare(&block)
		@tagCompare = block
		self
	end
	def defineTagValid(&block)
		@tagValid = block
		self
	end
	
	def cleanMainKey(k)
		@mainKeyClean.call(k)
	end
	
	def cleanTags(*tags)
		tags.map {|tag| @tagClean.call(tag)}
	end
	
	def compareMainKeys(ak,bk)
		@mainTagCompare.call(ak,bk)
	end
	
	def compareTags(atags, btags)
		results = []
		uatags = atags.uniq
		ubtags = btags.uniq
		
		uatags.each do |atag|
			found = false
			ubtags do |btag|
				found = @tagCompare.call(atag,btag)
				break if found
			end
			return false unless found
		end
			
		true
	end
	
	def validMainKey?(k)
		@mainKeyValid.call(k)
	end
	
	def validTags?(*tags)
		tags.each {|tag| return false unless @tagValid.call(tag) }
		true
	end
		
  end
  
  #this class is used to key things in a cache, supporting
  #	a main (primary) key for the data as well as tags. 
  class CacheKey
    attr_reader :mainKey, :schema

    Wildcard = '*'.to_sym
    
    def initialize(k, schema = SwapDmi::CacheKeySchema.default)
    	@schema = schema
    	@mainKey = @schema.cleanKey(k)
    	@tags = []
    end
    
    def tags()
      @tags.dup
    end

    def withTags!(*tags)
		xtags = @schema.cleanTags(*tags)
		@tags += xtags
		self
    end
    
    def withTags(*tags)
    	copy = SwapDmi::CacheKey.new(self.mainKey)
    	copy.withTags!( *(self.tags + tags) )
    end
    
    def matchMainKey(other)
    	@schema.compareMainKeys(self.mainKey,other)
    end
    
    def match(other)
    	return false unless @schema == other.schema
    	keyMatch = @schema.compareMainKeys(self.mainKey, other.key)
    	return false unless keyMatch
    	@schema.compareTags(self.tags, other.tags)
    end
    
    def =~(other)
    	case other
    		when SwapDmi::CacheKey then self.match(other)
    		else self.matchMainKey(other)
    	end 
    end
    
    def validId?()
    	@schema.validMainKey?(self.mainKey) and @schema.validTags?(*self.tags)
    end
    
  end
  
  #raised if attempt to save cache with a key wh/ cannot
  #	be used as a valid id (per configured cache logic)
  class CacheSaveError < StandardError
  	
  end
  
  # raised when either configuring a Cache in an invalid manner OR when using an incomplete/invalidly configured Cache
  class CacheSetupError < StandardError
  	
  end
  
  # raised if attempt to reconfigure a cache after attempting to use it
  class CacheReconfigureError < StandardError
  	
  end
  
  class Cache
    extend HasConfig
    extend TrackClassHierarchy

    EvictWhen = [:save,:get,:checkHas].freeze
    
    def initialize(id)
		assignId(id)
    	@internal = {}
    	@evictWhen = {}
    end
    
    def defineEvictWhen(whenKey)
    	raise SwapDmi::CacheSetupError.new unless SwapDmi::Cache::EvictWhen.includes?(whenKey)
    	case whenKey
    		when :all
    			SwapDmi::Cache::EvictWhen.each {|xWhenKey| @evictWhen[xWhenKey] = true}
    		else
    			@evictWhen[whenKey] = true
    	end
    	self
    end
    
    def defineReady(&block)
    	raise SwapDmi::CacheReconfigureError.new if @readyFlag
    	@ready = block
    	self
    end

    #All defines are listed up here
    def defineEviction(&block)
	  raise SwapDmi::CacheReconfigureError.new if @readyFlag
      @evict = block
      self
    end

    def defineInternalData(key, object)
	  raise SwapDmi::CacheReconfigureError.new if @readyFlag
      @internal[key] = object
      self
    end

    def defineValidId(&block)
		raise SwapDmi::CacheReconfigureError.new if @readyFlag
    	@validId = block
    	self
    end
    
    #defines the save block
    def defineSave(&block)
	  raise SwapDmi::CacheReconfigureError.new if @readyFlag
      @save = block
      self
    end

    def defineGet(&block)
	  raise SwapDmi::CacheReconfigureError.new if @readyFlag
      @getData = block
      self
    end
    
    def defineHas(&block)
		raise SwapDmi::CacheReconfigureError.new if @readyFlag
		@checkHas = block
		self
    end

    #All code is listed down here
    def ready
      return if @readyFlag
      raise SwapDmi::CacheSetupError.new if @save.nil?
      raise SwapDmi::CacheSetupError.new if @getData.nil?
      self.defineHas {|k| !self.getOne(k).nil? }
      self.instance_exec(&@ready) unless @ready.nil?
      @readyFlag = true
      self
    end

    # Code that will take in the block to save
    def save(key, data)
      self.ready
      
      unless @validId.nil?
		raise SwapDmi::CacheSaveError.new(key) unless self.instance_exec(key, &@validId)
      end
      
      self.evict(key) if @evictWhen[:save]
      self.instance_exec(key, data, &@save)
      self
    end
    def []=(k,d)
    	self.save(k,d)
    end

    # Retrieves the data from the cache
    def get(*ks)
	  self.ready
      self.evict(*ks) if @evictWhen[:get]
      self.instance_exec(ks, &@getData)
    end
    
    def getOne(k)
    	res = self.get(k)
    	res.empty ? nil : res[0]
    end
    def [](k)
    	self.getOne(k)
    end
    
    def has?(k)
    	self.ready
    	self.evict(*ks) if @evictWhen[:checkHas]
    	self.instance_exec(k, &@checkHas)
    end
    
    alias :has_key? :has?

    # Removes keys from cache automatically
    def evict(*keys)
	  self.ready
      self.instance_exec(keys, &@evict) unless @evict.nil?
      self
    end

    def internal
    	@internal.dup
    end
    private :internal
    	
  end
	
	module HasCache
		def self.extended(base)
			cacheTable = Hash.new do |instances,id|
				instances[id] = :default
			end
			base.class_variable_set(:@@caching, cacheTable)
			base.instance_eval { include SwapDmi::HasCache::Instance }
		end
		
		def dataCaching()
			self.class_variable_get(:@@caching)
		end
		
		def defineCaching(id,chid)
			self.dataCaching[id] = chid
			self
		end
		
		def dataCacher(id)
			chid = self.dataCaching[id]
			SwapDmi::Cache[chid]
		end
		
		module Instance
			def defineCaching(chid)
				self.class.dataCaching[self.id] = chid
				self
			end
		
			def dataCacher()
				self.class.dataCacher(self.id)
			end
		end
	end
	
	DefaultCacheKeySchema = SwapDmi::CacheKeySchema.new(:default)
  
	DefaultCache = SwapDmi::Cache.new(:default)
	DefaultCache.defineReady(&SwapDmi::DefaultCacheLogic::CacheReady)
	DefaultCache.defineSave(&SwapDmi::DefaultCacheLogic::CacheSave)
	DefaultCache.defineValidId(&SwapDmi::DefaultCacheLogic::CacheKeyValidId)
	DefaultCache.defineGetData(&SwapDmi::DefaultCacheLogic::CacheGet)
	DefaultCache.defineEviction(&SwapDmi::DefaultCacheLogic::CacheEvict)
	
	class ModelImpl
		extend HasCache
	end
	
	class ContextOfUse
		extend HasCache
	end
	
	class Model
		def dataCacher
			self.context.dataCacher
		end
	end
	
	class DataSource
		
		self.singleton_class.send(:alias_method, :basicInitModelCache, :initModelCache)
		
		def self.initModelCache()
			@modelToCache = Hash.new {|h,k| h[k] = :default} if @modelToCache.nil?
			self.basicInitModelCache()
		end
		
		def self.assignModelCacheForType(cacheId, modelType = self.defaultModelType)
			self.initModelCache
			@modelToCache[modelType] = cacheId
			self
		end
		
		def self.modelCacheIdForType(modelType = self.defaultModelType)
			@modelToCache[modelType]
		end
		
		def self.defaultDefaultModelCacheProc()
			dataSource = self
			Proc.new do |modelType|
				mtype = modelType
				proxy = SwapDmi::ProxyObject.new(SwapDmi::Cache) do
					dataSource.modelCacheIdForType(mtype)
				end
			end
		end
		
	end
	
	class SmartDataSource

		def self.defaultDefaultModelCacheProc()
			dataSource = self
			Proc.new do |modelType|
				mtype = modelType
				proxy = SwapDmi::ProxyObject.new(SwapDmi::Cache) do
					dataSource.modelCacheIdForType(mtype)
				end
				
				proxy.withProxyPreFilter(:[]) do |k|
					dataSource.touchModel(mtype, k)
				end
			end
		end
	end
	
end

