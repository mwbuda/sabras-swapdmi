
#
# main definiton of the Swap DMI domain model & data access layer
#
#	note that this is NOT Active Record based, it is an alternative to Active Record, 
#	developed for circumstances where Active Record is a poor fit, such as tying into many REST APIs
#
#	At the time of implementation, other options such as ActiveResource seemed to require very stringent adherence
#	to pure REST conventions, which was felt to have unfortunate implications on the design of the REST APIs one would want to integrate with.
#
#	This custom design does allow for the interesting feature to easily 'swap out' alternate implementations
#	of the model layer, eg. mock objects instead of actual REST calls (hence the swap in Swap DMI)
#
#	PLEASE NOTE that the types here are not usable on their own, you must define at least one instance of ModelLogic
#	and fully populate it with functors, 
#	the contents of this file define the overall base domain object schema and resulting API, 
#	with appropriate implemenation agnostic behavior defined
#
module SwapDmi	

	#
	# this class is used to define initializers for the framework itself,
	# 	eg. for Rails
	#
	class SwapDmiInit

		@@definedInits = {}

		def self.registerInitAs(key)
			@@definedInits[key] = self
		end
	
		def self.invoke(key = nil, args = {})
			initer = self
			unless key.nil?
				root = args[:srcroot]
				root = "swapdmi-init/#{key}" if root.nil?
				Kernel.require(root)
				initer = @@definedInits[key]
			end

			initer.new.invoke(args)
		end

		def invoke(args = {})
			throw 'unimplemented SwapDmi initialization'
		end
	end

	class SessionInfo
		attr_reader :id, :uid, :expire, :sundry
		
		def initialize(id, uid, expire)
			@id = id
			@uid = uid
			@expire = expire
			@sundry = []
		end
		
		def withSundry(args = {})
			@sundry.merge!(args)
			self
		end
		
	end

	DefaultSessionTracking = Proc.new {|session| session}
	DefaultSessionParsing = Proc.new {|raw| SessionInfo.new(raw[:id], raw[:uid], raw[:expire])}
	DefaultMissingLogic = Proc.new {|modelLogic,*keys| throw :undefinedModelLogic }
		
	class ModelLogic

		@@logging = Proc.new {|m| puts m}
		@@instances = {}
		@@config = Hash.new {|h,k| h[k] = Hash.new}
		@@defaultInstance = :swapdmi_base_default_model_logicid
			
		attr_reader :logicId
		
		def self.defineLogging(&logging)
			@@logging = logging
			Model.defineLogging(&logging)
		end

		def self.defineDefault(logicId)
			@@defaultInstance = logicId
		end
		
		def self.log(m)
			@@logging.call(m)
		end
		def log(m)
			@@logging.call(m)
		end

		def self.instance(logicId = nil)
			cleanLogicId = logicId.nil? ? @@defaultInstance : logicId
			instance = @@instances[cleanLogicId]
			throw "undefinedModelLogic: #{cleanLogicId}" if instance.nil?
			instance
		end
		
		def self.[](logicId)
			self.instance(logicId)
		end
		
		def self.default()
			self.instance(nil)
		end
		
		def self.config(instance = nil)
			instance.nil? ? @@config : @@config[instance]
		end
		def config()
			@@config[@logicId]
		end
		
		def initialize(id = :unnamed)
			@logicId = id
			@@instances[@logicId] = self
			@logics = Hash.new {|h,k| h[k] = Hash.new(&h.default_proc)}
			@missingLogic = DefaultMissingLogic
			self.defineSessionParsing(&SwapDmi::DefaultSessionParsing)
			self.defineSessionTracking(&SwapDmi::DefaultSessionTracking)
		end
		
		def defineSessionParsing(&parsing)
			@sessionParsing = parsing.nil? ? DefaultSessionParsing : parsing
			self
		end
		
		def defineSessionTracking(&tracking)
			@sessionTracking = tracking.nil? ? DefaultSessionTracking : tracking
			self
		end
		
		def define(*keys, &logic)
			root = @logics
			keys[0..-2].each {|k| root = root[k]}
			root[keys[-1]] = logic
			self
		end
		
		def parseSession(raw)
			@sessionParsing.call(raw)
		end

		def trackSession(session)
			@sessionTracking.call(session)
			session
		end
		
		def parseTrackSession(raw)
			self.trackSession(self.parseSession(raw))
		end
		
		def defines?(*keys)
			root = @logics
			keys[0..-2].each {|k| root = root[k]}
			root.has_key?(keys[-1])
		end
		
		def defineMissing(&logic)
			@missingLogic = logic
			self
		end
		
		def [](*keys)
			root = @logics
			keys[0..-2].each {|k| root = root[k]}
			@missingLogic.call(self,*keys) unless root.has_key?(keys[-1])
			root[keys[-1]]
		end
	  
	end
	
	DefaultMergeMissingLogic = Proc.new do |mlogic,*keys|
		viable = []
		unviable = []
		mlogic.delegates.each do |delegate|
			isViable = ModelLogic[delegate].defines?(*keys)
			set = isViable ? viable : unviable
			set << delegate
		end
		throw :undefinedModelLogic if viable.empty?
		unviable.each {|delegate| mlogic.defineExcludeFor(delegate, *keys)}
		mlogic.define(*keys)
	end

	#special purpose extension of ModelLogic which combines/merges logic from multiple implemenations
	#
	#
	class ModelLogicMerge < ModelLogic

		def initialize(id = :unnamed)
			super(id)
			@delegates = []
			@filters = Hash.new do |allFilters,*keys| allFilters[*keys] = Hash.new do |actionFilters,delegate|
				Proc.new {|*args| true}
			end end
		end

		def delegateTo(*ids)
			@delegates += ids
			@delegates.uniq!
			self
		end
		
		def defineFilterFor(delegate, *keys, &logic)
			@filters[*keys][delegate] = logic
			self
		end
		
		def defineExcludeFor(delegate, *keys)
			self.defineFilterFor(delegate, *keys) {|*args| false}
		end
		
		def defineAlwaysFor(delegate, *keys)
			self.defineFilterFor(delegate, *keys) {|*args| true}
		end

		def delegates()
			@delegates.dup
		end

		def define(*keys, &logic)
			merge = self
			filters = @filters[*keys]
			xlogic = !logic.nil? ? logic : Proc.new do |subres|
				res = []
				subres.each {|k,vs| res += vs}
				res
			end 
			
			mlogic = Proc.new do |*args|
				subresults = {}
				mk = nil
				merge.delegates.each do |delegate|
					next unless filters[id].call(*args)
					mk = delegate
					subresults[delegate] = ModelLogic[delegate][*keys].call(*args)
				end
				subresults.size == 1 ? subresults[mk] : xlogic.call(subresults)
			end
			
			super.define(*keys, &mlogic)
		end
	end

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
		
		def extractAndTrackSession(rawSession)
			self.logic.parseTrackSession(rawSession)
		end
		protected :extractAndTrackSession
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