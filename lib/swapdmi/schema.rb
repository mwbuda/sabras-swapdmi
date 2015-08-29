

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
	
	class ContextOfUse
		extend TrackClassHierarchy
		
		attr_reader :id, :config

		def default?()
			(@id == :default)
		end
		
		def initialize(id = :default)
			@id = id
			self.trackInstance(id, self)
			@config = {}
				
			if self.default?
				dcxt = self
				@dataSources = Hash.new {|h,k| h[k] = k.new(dcxt)}
				@impls = {:default => ModelImpl.default}
			else
				@impls = {}
				@dataSources = {}
			end
		end
		
		def setImpl(k, impl)
			@impls[k] = impl
			self
		end
		
		def defineDataSource(dsClass, sundry = {})
			@dataSources[dsClass] = dsClass.new(self,sundry)
			self
		end
		
		def impl(k = :default)
			@impls[k]
		end
		
		def impls()
			@impls.dup
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
		
		self.new(:default)
	end
	
	class Model
		attr_reader :contextOfUse, :id
		alias :context :contextOfUse

		@@logging = Proc.new {|m| puts m}
		def self.defineLogging(&logging)
			@@logging = logging
		end
		def log(m)
			@@logging.call(m)
		end
		def self.log(m)
			@@logging.call(m)
		end	

		def initialize(id, context = ContextOfUse.default, sundry = {})
			@contextOfUse = context
			@id = id
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

	end
	
	#
	# specialized Model which serves as root to access & manipulate the domain model,
	#	in other words the starting point for an API user; the 1st component they will use to access the model
	#
	#
	class DataSource < Model
		
		def initialize(context= ContextOfUse.default, sundry = {})
			super(context.id,context,sundry)
			
			@modelInit = Hash.new do |modelTypes,modelType| 
				modelTypes[modelType] = Proc.new {|id,cxt,dsource| Hash.new}
			end
			
			dsource = self
			context = self.contextOfUse
			modelInit = @modelInit
			@modelCache = Hash.new do |modelTypes,modelType|
				modelTypes[modelType] = Hash.new do |models,id|
					params = 
					models[id] = modelType.new(
						id, context, modelInit[modelType].call(id, context, dsource)
					)
				end
			end
		end
		
		def defineModelInit(modelType, &init)
			@modelInit[modelType] = init
		end
		
		def cacheModel(model)
			@modelCache[model.class][model.id] = model
		end
		
		def models()
			@modelCache
		end
		
		def self.[](k)
			cxt = ContextOfUse[k]
			return nil if cxt.nil?
			cxt[self]
		end
		alias :instance :[]
		
		def self.default()
			self[nil]
		end
		
	end
	
end




