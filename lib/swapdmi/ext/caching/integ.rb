
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
			SwapDmi.idValue( @cacheIdConfigMapping[modelType] )
		end
		
		#
		# map a model type to use a cache identified by contents of the given config property
		# 	EG: if mapModelCacheId(:monkey, X). objects of type X will use Cache[ self.config[:monkey] ]
		#
		def self.mapModelCacheIdToConfig(configKey, modelType = self.defaultModelType)
			self.initModelCache
			@cacheIdConfigMapping[modelType] = SwapDmi.idValue(configKey)
			self
		end
		
		def self.defaultDefaultModelCacheProc()
			Proc.new do |modelType|
				mtype = modelType
				dsource = self
				SwapDmi::ProxyObject.new(SwapDmi::Cache) do
					dsource.modelCacheIdForType(mtype)
				end
			end
		end
		
		def modelCacheIdForType(modelType = self.class.defaultModelType)
			configKey = self.class.modelCacheIdConfigKey(modelType)
			SwapDmi.idValue( self.config[configKey] )
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
				
				proxy.withProxyPreFilter(:[]) do |cache, k|
					dsource.touchModel(k, mtype) unless cache.has_key?(k)
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
