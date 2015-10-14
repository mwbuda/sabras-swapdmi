module SwapDmi
  SwapDmi.declareExtension(:caching)


  class CacheDescriptor
    attr_reader :key

    def initialize(k, *tags)
      @key = k
      @tags = tags
    end

    def tags()
      @tags.dup
    end

  end

  class Cache
    extend HasConfig
    extend TrackClassHierarchy

    def initialize(id)
      @internal = {}
      assignId = id;
    end

    #All defines are listed up here
    def defineEviction(&block)
      @evict = block
    end

    def defineInternalData(key, object)
      @internal[key] = object
    end

    #defines the save block
    def defineSave(&block)
      @save = block
    end

    def defineGetData(&block)
      @getData = block
    end

    #All code is listed down here
    def checkReady
      return if @readyFlag
      self.instance_exec(&@ready)
      @readyFlag = true
    end

    # Code that will take in the block to save
    def save(key, data)
      self.checkReady
      self.evict(key) if @evictWhen[:save]
      self.instance_exec(key, data, &@save)
    end

    # Retrieves the data from the hash
    def getData(k)
      self.evict(k) if @evictWhen[:get]
      self.instance_exec(k, &@getData)
    end

    # Removes keys from hash automatically
    def evict(tags)
      self.instance_exec(tags, &@evict)
    end

  end
  
	class HasCache

	  def self.extend(base)
		cacheTable = Hash.new do |instances,id|
		  instances[id] = :default
		end

	  end

	  def defineCache(cacheId)
		self.cache[self.id] = cacheId
		SwapDmi::Cache(id)
		self
	  end
	end

end

