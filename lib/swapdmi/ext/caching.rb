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
      self.save(key, data, expires, tags)
    end

    def cleanByKey(key)
      self.clean(key)
    end

    def cleanTags(tags)
      self.clean(tags)
    end

  end

  class Files
    extend Cache

    #Uses the key as the filename in order to save the file into it's proper location
    def save(key, data, location)
      f = File.new(location + "/" +key, "w+")
      f.write(data + "\n")
      f.close
    end

    def cleanKey(key, location)
      #check if file exists
      if(file?(location + "/" +key))
        file.unlink(location + "/" + key)
      end

    end

  end

end

