
module SwapDmi
	
	#special purpose extension of ModelImpl which combines/merges logic from multiple implemenations
	#
	#
	class MergedModelImpl < ModelImpl
		DefaultFilter = Proc.new {|delegate, *args| true}
		DefaultCallPriority = 0
		
		class AggregateResults
			attr_reader :arguments, :delegates
			
			def initialize(args = [], ords = [], subresults = {})
				@arguments = args.dup.freeze
				@delegates = ords.dup
				@subresults = {}
				@delegates.each do |delg|
					next unless subresults.has_key?(delg) 
					@subresults[delg] = subresults[delg]
				end
				@delegates.select! {|delg| @subresults.keys.include?(delg)}
				@delegates.freeze
				@subresults.freeze
			end
			
			def subresult(delegate)
				@subresults[delegate]
			end
			
			def results()
				@delegates.map {|delg| self.subresult(delg)}
			end
			
			def keyedResults()
				@subresults
			end
			
		end
		
		def initialize(id = :unnamed)
			super(id)
			@delegates = []
			
			@priority = Hash.new do |allPrioritys, keys| allPrioritys[keys] = Hash.new do |actionPrioritys, delegate|
				actionPrioritys[delegate] = nil
			end end
			
			@globalPriority = Hash.new do |delegatePrioritys, delegate|
				delegatePrioritys[delegate] = nil
			end
				
			@filters = Hash.new do |allFilters, keys| allFilters[keys] = Hash.new do |actionFilters,delegate|
				actionFilters[delegate] = DefaultFilter
			end end
			
			@globalFilters = Hash.new do |actionFilters,keys|
				actionFilters[keys] = DefaultFilter
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
		
		def defineGlobalCallPriorityFor(delegate, priority)
			@globalPriority[delegate] = priority
			self
		end
		
		def defineCallPriorityFor(delegate, priority, *keys)
			@priority[keys][delegate] = priority
			self
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
		
		def globalCallPriorityFor(delegate)
			@globalPriority[delegate]
		end
		
		def callPriorityFor(delegate, *keys)
			@priority[keys][delegate]
		end
		
		def ready!()
			@delegates.each {|dkey| SwapDmi::ModelImpl[dkey].ready!}
			super
		end
		
		def define(*keys, &logic)
			recv = self
			mlogic = Proc.new do |*args|
				subresults = {}
				
				delgs = recv.delegates.dup
				sortOrds = {}
				delgs.each do |delg|
					[recv.callPriorityFor(delg, *keys), recv.globalCallPriorityFor(delg)].each do |pri|
						sortOrds[delg] = pri
						break unless sortOrds[delg].nil?
					end
					sortOrds[delg] = SwapDmi::MergedModelImpl::DefaultCallPriority if sortOrds[delg].nil?
				end
				delgs.sort! do |da,db| 
					explicit = -1 * (sortOrds[da] <=> sortOrds[db])
					(explicit != 0) ? explicit : (da <=> db) 
				end
				
				delgs.each do |dkey|
					delegate = SwapDmi::ModelImpl[dkey]
					
					next if delegate.nil?
					next unless delegate.defines?(*keys)
					next unless recv.filterFor(dkey, *keys).call(dkey, delegate, *args)
					next unless recv.globalFilterFor(*keys).call(dkey, delegate, *args)
					
					subresults[dkey] = delegate[*keys].call(*args)
				end
				aggregate = SwapDmi::MergedModelImpl::AggregateResults.new(
					args, delgs, subresults
				)
				recv.instance_exec(aggregate, &logic)
			end
			
			super(*keys, &mlogic)
		end
	end
	
end

