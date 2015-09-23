
module SwapDmi
	
	#special purpose extension of ModelImpl which combines/merges logic from multiple implemenations
	#
	#
	class MergedModelImpl < ModelImpl
		DefaultFilter = Proc.new {|delegate, *args| true}
		
		def initialize(id = :unnamed)
			super(id)
			@delegates = []
			@filters = Hash.new do |allFilters, keys| allFilters[keys] = Hash.new do |actionFilters,delegate|
				actionFilters[delegate] = DefaultFilter
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

		def filterFor(delegate, *keys)
			@filters[keys][delegate]
		end
		
		def define(*keys, &logic)
			recv = self
			mlogic = Proc.new do |*args|
				subresults = {}
				recv.delegates.each do |dkey|
					next unless recv.filterFor(dkey, *keys).call(dkey, *args)
					dlogic = SwapDmi::ModelImpl[dkey]
					subresults[dkey] = dlogic[*keys].call(*args)
				end
				recv.instance_exec(args, subresults, &logic)
			end
			
			super(*keys, &mlogic)
		end
	end
	
end

