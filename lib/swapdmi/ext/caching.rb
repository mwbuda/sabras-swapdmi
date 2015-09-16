module SwapDmi
  SwapDmi.declareExtension(:caching)


  class Server

    @server

    #will automatically default to files as the server if one is not passed in
    def getServerType()
      if !server
        @server = "files"
      end
    end

    def save(key, data, expires, tags)
      if server == "files"
        Files.save(key, data, expires, tags)
      elsif server == "memcached"
        Memcached.save(key, data, expires, tags)
      elsif server == "redis"
        Redis.save(key, data, expires, tags)
      else
        Files.save(key, data, expires, tags)
      end
    end

    def clean(tags)
      if server == "files"
        Files.clean(tags)
      elsif server == "memcached"
        Memcached.clean(tags)
      elsif server == "redis"
        Redis.clean(tags)
      else
        Filse.clean(tags)
      end
    end

  end

  class Files
    def save(key, data, expires, tags)
      #Code here to save the files
    end

    def clean(tags)

    end
  end

  class Memcached
    def save(key, data, expires, tags)

    end

    def clean(tags)

    end
  end

  class Redis
    def save(key, data, expires, tags)

    end

    def clean(tags)

    end
  end

end

