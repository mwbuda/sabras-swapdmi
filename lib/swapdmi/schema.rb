

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
	
	class Model
		attr_reader :logic

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

		def initialize(logic = ModelLogic.new, sundry = {})
			@logic = logic
			self.initializeModel(sundry)
		end
		
		def initializeModel(sundry = {})
			#define as neccesary in subclasses
		end
		protected :initializeModel
		
		def config()
			self.logic.config
		end

	end
	
	#this is mostly a marker interface for models
	#	of which there is generally exactly one (singleton); 
	#	and which serve as 'access' points for the rest of the application
	#	
	#	eg; ea. controller which needs access to user data will start at a shared Users model,
	#	which is a DataSource, as opposed to building their own Profile Objects from scratch
	#
	#	from a top level perspective, the correct instance should be accessed via the class instance/[] methods
	#	instances are automagically identified by the id of the underlying ModelLogic
	#
	#	a 'default' mechanism is provided so the application can just ask for X.instance and get the right one,
	#	configure this with defineDefaultInstance(logicId)
	class DataSource < Model
		
		@@instances = Hash.new {|h,k| h[k] = Hash.new}
		@@defaultInstance = {}
		
		def initialize(logic = ModelLogic.new, sundry = {})
			@@instances[self.class][logic.logicId] = self
			super(logic,sundry)
		end
		
		def self.dataSourceTypes
			@@instances.keys
		end
		
		def self.defineDefaultLogic(logicId)
			@@defaultInstance[self] = logicId
		end
		
		def self.instance(logicId = nil)
			instance = @@instances[self][ logicId.nil? ? @@defaultInstance[self] : logicId ]
			instance = @@instances[self][ModelLogic.default.logicId] if instance.nil?
			instance
		end
		
		def self.[](logicId)
			self.instance(logicId)
		end
		
		def self.default()
			self.instance(nil)
		end
		
	end
	
end




