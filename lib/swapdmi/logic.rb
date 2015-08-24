
#
# features & components for implementing & managing model/persistence logic
#	these are the tools a SwapDMI user uses to actually interface with their choice(s)
#	of database, remote API, etc.
#
#
#
#

module SwapDmi
	
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
		end
		
		def define(*keys, &logic)
			root = @logics
			keys[0..-2].each {|k| root = root[k]}
			root[keys[-1]] = logic
			self
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
	
	#special purpose extension of ModelLogic which combines/merges logic from multiple implemenations
	#
	#
	class ModelLogicMerge < ModelLogic
		
		def initialize(id = :unnamed)
			super(id)
			@delegates = []
			@filters = Hash.new do |allFilters, keys| allFilters[keys] = Hash.new do |actionFilters,delegate|
				Proc.new {|*args| true}
			end end
		end

		def delegateTo(*ids)
			@delegates += ids
			@delegates.uniq!
			self
		end
		
		def defineFilterFor(delegate, *keys, &logic)
			@filters[keys][delegate] = logic
			self
		end
		
		def defineExcludeFor(delegate, *keys)
			self.defineFilterFor(delegate, *keys) {|dkey, *args| false}
		end
		
		def defineAlwaysFor(delegate, *keys)
			self.defineFilterFor(delegate, *keys) {|dkey, *args| true}
		end

		def delegates()
			@delegates.dup
		end

		def define(*keys, &logic)
			delegates = @delegates
			filters = @filters[keys]
			
			mlogic = Proc.new do |*args|
				subresults = {}
				delegates.each do |dkey|
					next unless filters[dkey].call(dkey, *args)
					dlogic = ModelLogic[dkey]
					subresults[dkey] = dlogic[*keys].call(*args)
				end
				logic.call(subresults)
			end
			
			super(*keys, &mlogic)
		end
	end
	
end
