module SwapDmi
  SwapDmi.declareExtension(:caching)

  class Cache

    @server
    @key
    @data
    #default logic for expires is set to 1440 minutes or 1 day
    @expires = 1440
    @tags = []

    def save(key, data, expires, tags)
      server.save(key, data, expires, tags)
    end

    def cleanByTag(tag)
      server.clean(tag)
    end

    def cleanTags(tags)
      server.clean(tags)
    end

  end

end

