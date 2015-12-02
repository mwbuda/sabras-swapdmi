
module SwapDmi
	
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
			@cacheIdConfigMapping = {} if @cacheIdConfigMapping.nil?
			self.basicInitModelCache()
		end
		
		def self.modelCacheIdConfigKey(modelType = self.defaultModelType)
			self.initModelCache
			@cacheIdConfigMapping.each {|k,v| Rails.logger.debug("get key for model type OPT: #{k} => #{v}") }
			res = @cacheIdConfigMapping[modelType]
			Rails.logger.debug("get key for model type RESULT: #{modelType} => #{res}")
			res
		end
		
		def self.mapModelCacheIdToConfig(configKey, modelType = self.defaultModelType)
			self.initModelCache
			@cacheIdConfigMapping.each {|k,v| Rails.logger.debug("cfg key for model type CURR: #{k} => #{v}") }
			@cacheIdConfigMapping[modelType] = configKey
			Rails.logger.debug("get key for model type NEW: #{modelType} => #{configKey}")
			@cacheIdConfigMapping.each {|k,v| Rails.logger.debug("cfg key for model type SANITY: #{k} => #{v}") }
			self
		end
		
		def self.defaultDefaultModelCacheProc()
			Proc.new do |modelType|
				mtype = modelType
				dsource = self
				SwapDmi::ProxyObject.new(SwapDmi::Cache) do
					$railsLogger.debug("!!!Proxy dsource = #{self}")
					$railsLogger.debug("!!!Proxy mtype = #{mtype}")
					$railsLogger.debug("!!!Proxy result = #{dsource.modelCacheIdForType(mtype)}")
					dsource.modelCacheIdForType(mtype)
				end
			end
		end
		
		def modelCacheIdForType(modelType = self.class.defaultModelType)
			configKey = self.class.modelCacheIdConfigKey(modelType)
			Rails.logger.debug("get cache for model type: #{modelType} => #{configKey} => #{self.config[configKey]}")
			self.config[configKey]
		end
		
	end
	
	class SmartDataSource

		def self.defaultDefaultModelCacheProc()
			Proc.new do |modelType|
				mtype = modelType
				dsource = self
				
				proxy = SwapDmi::ProxyObject.new(SwapDmi::Cache) do
					dsource.modelCacheIdForType(mtype)
				end
				
				proxy.withProxyPreFilter(:[]) do |k|
					dsource.touchModel(k, mtype)
				end
				
				proxy
			end
		end
		
	end

	SwapDmi.addHookForExtension('integrate logging with caching', :caching, :logging) do
		class SwapDmi::Cache
			extend HasLog
		end
	end
		
end
