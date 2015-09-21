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

    def getData()
      self.evict if @evictWhen[:get]
      self.instance_exec(k, &@getData)
    end

    def cleanByKey(key)
      server.clean(key)
    end

    def cleanTags(tags)
      server.clean(tags)
    end

    def evict()
      self.instance_exec(&@evict)
    end

  end


end

