module SwapDmi
  SwapDmi.declareExtension(:caching)

  class Cache

    def initialize()
      @internal = {}
    end

    def defineEviction(&block)
      @evict = block
    end

    def defineInternalData(key, object)
      @internal[key] = object
    end

    def doEvictWhen(*checkpoints)
      checkpoints.each {|cp| @evictWhen[cp] = true}
    end

    def checkReady
      return if @readyFlag
      self.instance_exec(&@ready)
      @readyFlag = true
    end

    def save(key, data, *tags)
      self.checkReady
      self.evict(tags) if @evictWhen[:save]
      self.instance_exec(key, data, tags, &@save)
    end

    def defineSave(&block)
      @save = block
    end

    def getData(k, tags)
      self.evict(tags) if @evictWhen[:get]
      @getData.call(k)
      self.instance_exec(k, &@getData)
    end

    def cleanByKey(key)
      self.evict(key)
    end

    def cleanTags(tags)
      self.evict(tags)
    end

    def evict(tags)
      self.instance_exec(&@evict)
    end

  end


end

