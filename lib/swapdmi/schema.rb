

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
		
		#model init is used to initialize models in the cache
		def self.initModelInit
			return unless @modelInit.nil?
			@modelInit = Hash.new do |initCodes,modelType| 
				initCodes[modelType] = Proc.new {|id| Hash.new}
			end
			self
		end
		def self.modelInit(modelType = nil)
			cModelType = modelType.nil? ? self.defaultModelType : modelType
			self.initModelInit
			@modelInit[cModelType]
		end
		def self.defineModelInit(modelType = nil, &init)
			cModelType = modelType.nil? ? self.defaultModelType : modelType
			self.initModelInit
			@modelInit[cModelType] = init
			self
		end
		
		#default model type establishes a base model type,
		#	which will be used implicitly
		def self.defineDefaultModelType(type)
			@defaultModelType = type
			self
		end
		def self.defaultModelType()
			@defaultModelType
		end
		
		#fetch resolves nil: if true will create models on demand in cache
		#	otherwise they must be touched or cached manually
		def self.initFetchResolvesNil()
			@fetchResolvesNil = Hash.new {|h,k| h[k] = false} if @fetchResolvesNil.nil?
			self
		end
		def self.fetchResolvesNil(modelType = nil, v = true)
			cModelType = modelType.nil? ? self.defaultModelType : modelType
			self.initFetchResolvesNil
			@fetchResolvesNil[cModelType] = v
			self
		end
		def self.fetchResolvesNil?(modelType = nil)
			cModelType = modelType.nil? ? self.defaultModelType : modelType
			self.initFetchResolvesNil
			@fetchResolvesNil[cModelType]
		end
		
		def initialize(context = SwapDmi::ContextOfUse.default, sundry = {})
			#set up the model cache
			dsource = self
			@modelCache = Hash.new do |modelTypes,modelType|
				modelTypes[modelType] = Hash.new do |models,id|
					modelInit = dsource.class.modelInit(modelType)
					params = dsource.instance_exec(id, &modelInit)
					models[id] = modelType.new(id, dsource.context, params)
				end
			end
			
			#call super
			super(context.id, context, sundry) 
			context.assignDataSource(self)
		end
		
		# instantiates a model in the cache using the defined init logic
		def touchModel(id, type = nil)
			ctype = type.nil? ? self.class.defaultModelType : type
			@modelCache[type][id]
		end
		
		# manually caches a model in the cache
		#	note that this allows you to cache a model w/ a different contextOfUse than the governing dataSource
		def cacheModel(model)
			@modelCache[model.class][model.id] = model
		end
		
		# fetch a model from the cache
		#	if you are not resolving nil for the type, then will return nil if not previously manually touched/cached
		def fetchModel(id, type = nil)
			ctype = type.nil? ? self.class.defaultModelType : type
			if self.class.fetchResolvesNil?(ctype)
				@modelCache[ctype][id]
			elsif !@modelCache[ctype].keys.include?(id)
				nil
			else
				@modelCache[ctype][id]
			end
		end
		
		def [](id, type = nil)
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




