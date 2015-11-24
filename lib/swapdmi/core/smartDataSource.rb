
module SwapDmi
	
	#
	# data source wh/ will automatically instantiate objects of the requested type when
	#	asked, rather than relying on API users to manually insert them into the cache
	#
	class SmartDataSource < DataSource

		#override the default init model cache behavior, so we have a richer default
		#	model cache initialization proc, wh/ will use the other hooks we have on SmartDataSource
		def self.defaultDefaultModelCacheProc()
			Proc.new do |modelType| 
				Hash.new {|models,id| self.touchModel(id, modelType) }
			end
		end
		
		#model init is used to initialize models in the cache
		def self.initModelInit
			@modelPreInit = Hash.new do |initCodes,modelType| 
				initCodes[modelType] = Proc.new {|id| Hash.new}
			end if @modelPreInit.nil?
			
			@modelPostInit = Hash.new if @modelPostInit.nil?
			
			self
		end
		
		#pre init populates the sundry arguments to a model instance
		def self.modelPreInit(modelType = self.defaultModelType)
			self.initModelInit
			@modelPreInit[modelType]
		end
		def self.defineModelPreInit(modelType = self.defaultModelType, &init)
			self.initModelInit
			@modelPreInit[modelType] = init
			self
		end
		
		#post init can modify a newly built model object immediatly after construction
		def self.modelPostInit(modelType = nil)
			self.initModelInit
			@modelPostInit[modelType]
		end
		def self.defineModelPostInit(modelType = self.defaultModelType, &init)
			self.initModelInit
			@modelPostInit[modelType] = init
			self
		end
		
		#fetch resolves nil: if true will create models on demand in cache
		#	otherwise they must be touched or cached manually
		def self.initFetchResolvesNil()
			@fetchResolvesNil = Hash.new {|h,k| h[k] = false} if @fetchResolvesNil.nil?
			self
		end
		def self.fetchResolvesNil(modelType = self.defaultModelType, v = true)
			self.initFetchResolvesNil
			@fetchResolvesNil[modelType] = v
			self
		end
		def self.fetchResolvesNil?(modelType = self.defaultModelType)
			self.initFetchResolvesNil
			@fetchResolvesNil[modelType]
		end
		
		# instantiates a modelfrom this data source 
		#	using the defined init logic, and linked to this datasource's contextOfUse
		# will NOT store the model in the cache. this must be done explicitly after touching the model instance
		#
		def touchModel(id, modelType = self.class.defaultModelType, xsundry = {})
			return self.modelCache[modelType][id] if self.modelCache[modelType].has_key?(id) 
			
			modelPreInit = self.class.modelPreInit(modelType)
			params = self.instance_exec(id, &modelPreInit)
			params.merge!(xsundry) unless xsundry.nil?
			
			mx = modelType.new(id, self.context, params)
			
			modelPostInit = self.class.modelPostInit(modelType)
			self.instance_exec(mx, &modelPostInit) unless modelPostInit.nil?
			
			self.modelCache[modelType][id] = mx
			
			mx
		end		
		
		def fetchModel(id, type = self.class.defaultModelType)
			mcache = self.modelCache[type]
			throw :unsupportedType if mcache.nil?
			if self.class.fetchResolvesNil?(type)
				mcache[id]
			elsif !mcache.has_key?(id)
				nil
			else
				mcache[id]
			end
		end
		
	end
	
end
