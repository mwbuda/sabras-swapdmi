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

    def initialize()
      @internal = {}
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


    #all code is listed down here

    def doEvictWhen(*checkpoints)
      checkpoints.each {|cp| @evictWhen[cp] = true}
    end

    # Checks if hash is ready
    def checkReady
      return if @readyFlag
      self.instance_exec(&@ready)
      @readyFlag = true
    end

    # Cod that will take in the block to save
    def save(key, data, &block)
      self.checkReady
      self.evict(tags) if @evictWhen[:save]
      self.instance_exec(key, data, tags, &@save)
    end

    # Retrieves the data from the hash
    def getData(k, tags)
      self.evict(tags) if @evictWhen[:get]
      @getData.call(k)
      self.instance_exec(k, &@getData)
    end

    # Removes keys from hash automatically
    def evict(tags)
      self.instance_exec(tags, &@evict)
    end

  end

end

