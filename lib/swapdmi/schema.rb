

#
# features & components for defining a data domain model schema
#	in other words, the API an application will use to access & manipulate data,
#	separate from how that data is actually persisted
#
#
#
#
#

module SwapDmi
	
	#TODO: subcontext/extend-context feature,
	#	where a Context instance will delegate to another if missing impl, config, etc
	class ContextOfUse
		extend TrackClassHierarchy
		extend HasConfig
		
		DefaultContextId = :default 
		DefaultImplId = :default
		
		def initialize(id = :default)
			self.assignId(id)
				
			if self.default?
				dcxt = self
				@dataSources = Hash.new {|h,k| h[k] = k.new(dcxt)}
				@impls = {:default => SwapDmi::ModelImpl.default}
			else
				@impls = {}
				@dataSources = {}
			end
		end
		
		def setImpl(k, implk)
			ck, ci = implk.nil? ? [:default,k] : [k,implk]
			@impls[ck] = ci
			self
		end
		
		def defineDataSource(dsClass, sundry = {})
			dsClass.new(self,sundry)
			self
		end
		def assignDataSource(dataSource)
			throw :misMatchedContext if dataSource.context != self
			@dataSources[dataSource.class] = dataSource
			self
		end
		
		def impl(k = :default)
			SwapDmi::ModelImpl[ @impls[k] ]
		end
		
		def impls()
			res = {}
			@impls.each {|k,ik| res[k] = SwapDmi::ModelImpl[ik] }
			res
		end
		
		def dataSources()
			res = @dataSources.dup
		end
		
		def dataSource(dsClass)
			@dataSources[dsClass]
		end
		
		def [](dsClass)
			self.dataSource(dsClass)
		end
	end
	
	DefaultContextOfUse = SwapDmi::ContextOfUse.new
	
	class Model
		extend HasId
		
		attr_reader :contextOfUse
		alias :context :contextOfUse

		def initialize(id, context = ContextOfUse.default, sundry = {})
			self.assignId(id)
			@contextOfUse = context
			self.initializeModel(sundry)
		end
		
		def initializeModel(sundry = {})
			#define as neccesary in subclasses
		end
		protected :initializeModel
		
		def config()
			self.contextOfUse.config
		end
		
		def impl(k = :default)
			self.contextOfUse.impl(k)
		end
		
		def impls()
			self.contextOfUse.impls
		end

	end
	
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
			
			@defaultBuildModelCache = Proc.new {|modelType| Hash.new } if @defaultBuildModelCache.nil?
			self
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
		def cacheModel(model)
			mcache = self.modelCache[model.class]
			throw :unsupportedType if mcache.nil?
			mcache[model.id] = model
		end
		
		# fetch a model from the cache
		#	if you are not resolving nil for the type, then will return nil if not previously manually touched/cached
		def fetchModel(id, type = self.class.defaultModelType)
			mcache = self.modelCache[model.class]
			throw :unsupportedType if mcache.nil?
			mcache[type][id]
		end
		
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
	
	#
	# data source wh/ will automatically instantiate objects of the requested type when
	#	asked, rather than relying on API users to manually insert them into the cache
	#
	class SmartDataSource < DataSource

		#override the default init model cache behavior, so we have a richer default
		#	model cache initialization proc, wh/ will use the other hooks we have on SmartDataSource
		def self.initModelCache()
			@defaultBuildModelCache = Proc.new do |modelType| 
				Hash.new do |models,id|
					modelPreInit = self.class.modelPreInit(modelType)
					params = self.instance_exec(id, &modelPreInit)
					
					mx = modelType.new(id, self.context, params)
					
					modelPostInit = self.class.modelPostInit(modelType)
					self.instance_exec(mx, &modelPostInit) unless modelPostInit.nil?
					
					models[id] = mx
				end
			end if @defaultBuildModelCache.nil?
			
			super
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
		
		# instantiates a model in the cache using the defined init logic
		def touchModel(id, type = self.class.defaultModelType)
			mcache = self.modelCache[type]
			throw :unsupportedType if mcache.nil?
			self.modelCache[id]
		end
		
		def fetchModel(id, type = self.class.defaultModelType)
			mcache = self.modelCache[type]
			throw :unsupportedType if mcache.nil?
			if self.class.fetchResolvesNil?(type)
				mcache[id]
			elsif !mcache.keys.include?(id)
				nil
			else
				mcache[id]
			end
		end
		
	end
	
end




