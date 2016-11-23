
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
		extend HasCache
		
		def self.defineModelCacheById(cacheId, modelType = self.defaultModelType)
			self.defineCaching(modelType, cacheId)
			self
		end
		
		def self.defaultDefaultModelCacheProc()
			Proc.new do |modelType|
				mtype = modelType
				dsource = self
				SwapDmi::ProxyObject.new(SwapDmi::Cache) do
					dsource.dataCacherId(mtype)
				end
			end
		end
		
	end
	
	class SmartDataSource

		def self.defaultDefaultModelCacheProc()
			Proc.new do |modelType|
				mtype = modelType
				dsource = self
				
				proxy = SwapDmi::ProxyObject.new(SwapDmi::Cache) do
					dsource.dataCacherId(mtype)
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
