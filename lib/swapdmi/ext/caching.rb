module SwapDmi
  SwapDmi.declareExtension(:caching)

  class Cache

    defineInternalData(k, &initdata)
    @internal[k] = initdata.call

    def defineEviction(&block)
      @evict = block
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
      self.evict if @evictWhen[:save]
      self.instance_exec(key, data, tags, &@save)
    end

    def defineSave(&block)
      @save = block
    end

    def getData(tags)
      self.evict(tags) if @evictWhen[:get]
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

