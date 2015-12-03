module SwapDmi
	SwapDmi.declareExtension(:caching)
  
  # this class is used along with CacheKey for custom
  #		match/keying semantics w/i a cache.
  class CacheKeySchema
		extend TrackClassHierarchy
	
		def initialize(id)
			self.assignId(id)
		end
	
		def defineMainKeyUnique(&block)
			@mainKeyUnique = block
			self
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
			@mainKeyCompare.call(ak,bk)
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
		
		# if true, provided main key will only ever refer to a single, unique record
		# 	if false, many possible items in the cache could be returned by provided main key
		def uniqueMainKey?(k)
			@mainKeyUnique.call(k)
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
    
    def self.wildcard?(x)
    	case x
    		when Wildcard then true
    		when Wildcard.to_s then true
    		when SwapDmi::CacheKey then ([x.mainKey] + x.tags).each do |kp|
    			return true if self.wildcard?(kp)
    		end 
    		else false
    	end
    end
    
    def self.wildcard()
    	self.new(SwapDmi::CacheKey::Wildcard)
    end
    
    def initialize(k, schema = SwapDmi::CacheKeySchema.default)
    	@schema = schema
    	@mainKey = @schema.cleanMainKey(k)
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
    
    def unique?()
    	@schema.mainKeyUniqueMatch?(self.mainKey)
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

    EvictWhen = [:save,:get,:checkHas,:all].freeze
    
    def initialize(id)
			assignId(id)
    	@internal = {}
    	@evictWhen = {}
    end
    
    def defineEvictWhen(whenKey)
    	raise SwapDmi::CacheSetupError.new unless SwapDmi::Cache::EvictWhen.include?(whenKey)
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

    def defineGetMany(&block)
	  	raise SwapDmi::CacheReconfigureError.new if @readyFlag
      @getMany = block
      self
    end
    
    def defineHas(&block)
			raise SwapDmi::CacheReconfigureError.new if @readyFlag
			@checkHas = block
			self
    end
    
    def defineGetOne(&block)
			raise SwapDmi::CacheReconfigureError.new if @readyFlag
			@getOne = block
			self
    end

    #All code is listed down here
    def ready
      return if @readyFlag
      raise SwapDmi::CacheSetupError.new if @save.nil?
      raise SwapDmi::CacheSetupError.new if @getMany.nil?
			raise SwapDmi::CacheSetupError.new if @getOne.nil?
      @checkHas = Proc.new {|k| !self.getOne(k).nil? } if @checkHas.nil?
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
    def getMany(*ks)
	  	self.ready
      self.evict(*ks) if @evictWhen[:get]
      self.instance_exec(ks, &@getMany)
    end
    
    def getOne(k)
			self.ready
			self.evict(k) if @evictWhen[:get]
			self.instance_exec(k, &@getOne)
    end
    def [](k)
    	self.getOne(k)
    end
    
    def has?(k)
    	self.ready
    	self.evict(k) if @evictWhen[:checkHas]
    	self.instance_exec(k, &@checkHas)
    end
    
    alias :has_key? :has?
    alias :hasKey? :has?

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
	
end

require 'swapdmi/ext/caching/defaultCacheLogic'
require 'swapdmi/ext/caching/integ'
SwapDmi.activateExtensionHooks(:caching)

