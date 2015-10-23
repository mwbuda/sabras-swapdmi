
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
			
			@globalFilters = Hash.new do |actionFilters,delegate|
				actionFilters[delegate] = DefaultFilter
			end
		end

		def delegateTo(*ids)
			@delegates += ids
			@delegates.uniq!
			self
		end
		
		def defineGlobalFilterFor(*keys, &logic)
			@globalFilters[keys] = logic
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

		def globalFilterFor(*keys)
			@globalFilters[keys]
		end
		
		def filterFor(delegate, *keys)
			@filters[keys][delegate]
		end
		
		def define(*keys, &logic)
			recv = self
			mlogic = Proc.new do |*args|
				subresults = {}
				recv.delegates.each do |dkey|
					delegate = SwapDmi::ModelImpl[dkey]
					
					next if delegate.nil?
					next unless delegate.defines?(*keys)
					next unless recv.filterFor(dkey, *keys).call(dkey, delegate, *args)
					next unless recv.globalFilterFor(*keys).call(dkey, delegate, *args)
					
					subresults[dkey] = delegate[*keys].call(*args)
				end
				recv.instance_exec(args, subresults, &logic)
			end
			
			super(*keys, &mlogic)
		end
	end
	
end

