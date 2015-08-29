
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
	
	class ModelImpl
		extend TrackClassHierarchy
		
		attr_reader :id
		
		@@config = Hash.new {|h,k| h[k] = Hash.new}
		
		def self.config(instance = nil)
			instance.nil? ? @@config : @@config[instance]
		end
		def config()
			@@config[@id]
		end
		
		def initialize(id = :unnamed)
			@id = id
			self.class.trackInstance(id,self)
			@logics = HierarchicalIndex.new
			@missingLogic = DefaultMissingLogic
		end
		
		def define(*keys, &logic)
			@logics.set(keys,logic)
			self
		end
		
		def defines?(*keys)
			@logics.has?(keys)
		end
		
		def defineMissing(&logic)
			@missingLogic = logic
			self
		end
		
		def [](*keys)
			logic = @logics[*keys]
			@missingLogic.call(self,*keys) if logic.nil?
			logic
		end
	  
	end
	
	#special purpose extension of ModelImpl which combines/merges logic from multiple implemenations
	#
	#
	class MergedModelImpl < ModelImpl
		
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
