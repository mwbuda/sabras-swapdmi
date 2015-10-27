
module SwapDmi
	
	#TODO: make modelCache properly align for subclass types
	#	EG if we have a modelCache init code for Type A,
	#	instances of type B wh/ extends A should use model cache for type A,
	#	unless we specifically create an additional model cache init def for type B
	
	#
	# specialized Model which serves as root to access & manipulate the domain model,
	#	in other words the starting point for an API user; the 1st component they will use to access the model
	#
	#
	class DataSource < Model
		
		#model cache is used to store managed Model objects from this datasource by type & id
		#	by default, you will still need to manually put models into the cache, using dataSource.cacheModel(model),
		#	
		#	see SmartDataSource for a extended subclass with hooks to automatically instantiate model instances
		attr_reader :modelCache
		
		def self.initModelCache()
			@typeWhiteList = [] if @typeWhiteList.nil?
			@typeBlackList = [] if @typeBlackList.nil?
			
			dsourceKlass = self
			@buildModelCache = Hash.new do |bmc,mt|
				allow = true
				allow &= dsourceKlass.whiteListedModelType?(mt)
				allow &= !dsourceKlass.blackListedModelType?(mt)
				bmc[mt] = allow ? dsourceKlass.defaultModelCacheProc : nil
			end if @buildModelCache.nil?
			
			@defaultBuildModelCache = self.defaultDefaultModelCacheProc if @defaultBuildModelCache.nil?
			self
		end
		
		# this method provides the default value to use as the default model cache constructor
		def self.defaultDefaultModelCacheProc()
			Proc.new {|modelType| Hash.new }
		end
		
		# get default proc used to build model cache for ea. handled type
		def self.defaultModelCacheProc()
			self.initModelCache
			@defaultBuildModelCache
		end
		
		# get proc used to build model cache for indicated handled type
		def self.modelCacheProc(modelType = self.defaultModelType)
			self.initModelCache
			@buildModelCache[modelType]
		end
		
		# define initialization of the model cache for the indicated type
		def self.defineModelCacheForType(modelType = self.defaultModelType, &buildCache)
			self.initModelCache
			throw :unsupportedType unless self.whiteListedModelType?(modelType)
			throw :unsupportedType if self.blackListedModelType?(modelType)
			@buildModelCache[modelType] = buildCache
			self
		end
		
		# define initialization of the model cache for all types.
		#	will be overridden by type specific cache definitions
		def self.defineModelCache(&buildCache)
			@defaultBuildModelCache = buildCache
			self
		end
		
		# if one or more model types are white listed,
		#	then ONLY instnaces of the indicated types (or subclasses) will be handled
		def self.whiteListedModelTypes()
			self.initModelCache
			@typeWhiteList.dup
		end
		def self.whiteListModelType(modelType)
			self.whiteListModelTypes(modelType)
		end
		def self.whiteListModelTypes(*modelTypes)
			self.initModelCache
			@typeWhiteList += modelTypes
			extantModelTypes = @buildModelCache.keys
			extantModelTypes.each {|mt| defineModelCacheForType(&nil) unless whiteListedModelType?(mt)} 
			self
		end
		def self.whiteListedModelType?(modelType)
			self.initModelCache
			return true if @typeWhiteList.empty?
			
			root = modelType
			tree = []
			until root.nil?
				tree << root
				root = root.superclass
			end
			
			tree.each {|mtx| return true if @typeWhiteList.include?(mtx)}
			false
		end
		
		# if a model type is black listed, then instnaces of itself & subclasses will not be supported
		#	by the model cache
		def self.blackListedModelTypes()
			self.initModelCache
			@typeBlackList.dup
		end
		def self.blackListModelType(modelType)
			self.blackListModelTypes(modelType)
		end
		def self.blackListModelTypes(*modelTypes)
			self.initModelCache
			@typeBlackList += modelTypes
			modelTypes.each {|mt| defineModelCacheForType(mt,&nil) }
			self
		end
		def self.blackListedModelType?(modelType)
			self.initModelCache
			return false if @typeBlackList.empty?
			
			root = modelType
			tree = []
			until root.nil?
				tree << root
				root = root.superclass
			end
			
			tree.each {|mtx| return true if @typeBlackList.include?(mtx)}
			false
		end
		
		#default model type establishes a base model type,
		#	which will be used implicitly
		def self.defineDefaultModelType(type)
			@defaultModelType = type
			self
		end
		def self.defineModelType(type)
			self.defineDefaultModelType(type)
		end
		def self.defaultModelType()
			@defaultModelType
		end
		
		def initialize(context = SwapDmi::ContextOfUse.default, sundry = {})
			#set up the model cache
			dsource = self
			@modelCache = Hash.new do |modelTypes, modelType|
				modelTypes[modelType] = dsource.instance_exec(modelType, &dsource.class.modelCacheProc(modelType))
			end
			
			#call super
			super(context.id, context, sundry) 
			context.assignDataSource(self)
		end
		
		# manually caches a model in the cache
		#	note that this allows you to cache a model w/ a different contextOfUse than the governing dataSource
		def cacheModel(*models)
			models.each do |model|
				mcache = self.modelCache[model.class]
				throw :unsupportedType if mcache.nil?
				mcache[model.id] = model
			end
			self
		end
		
		def clearModelCache(*modelTypes)
			modelTypes = [self.class.modelType] if modelTypes.empty?
			modelTypes.compact!
			modelTypes.each {|modelType| self.modelCache.delete(modelType) }
			self
		end
		
		# fetch a model from the cache
		#	if you are not resolving nil for the type, then will return nil if not previously manually touched/cached
		def fetchModel(id, type = self.class.defaultModelType)
			mcache = self.modelCache[type]
			throw :unsupportedType if mcache.nil?
			mcache[id]
		end
		
		def hasModel?(id, type = self.class.defaultModelType)
			mcache = self.modelCache[type]
			throw :unsupportedType if mcache.nil?
			return mcache.has_key?(id)
		end
		
		alias :has? :hasModel?
		alias :has_key? :hasModel? 
		
		def [](id, type = self.class.defaultModelType)
			self.fetchModel(id,type)
		end
		
		def self.[](k)
			cxt = SwapDmi::ContextOfUse[k]
			return nil if cxt.nil?
			cxt[self]
		end
		def self.instance(k)
			self[k]
		end
		
		def self.default()
			self[nil]
		end
		
	end
	
end
