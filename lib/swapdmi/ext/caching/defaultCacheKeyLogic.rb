

#
#defines default cache key handling logic
#
#

module SwapDmi
module DefaultCacheKeyLogic
	
	def self.configureCacheKeySchema(schema)
		schema.defineMainKeyClean(&SwapDmi::DefaultCacheKeyLogic::CacheKeyClean)
		schema.defineTagClean(&SwapDmi::DefaultCacheKeyLogic::CacheKeyClean)
		
		schema.defineMainKeyCompare(&SwapDmi::DefaultCacheKeyLogic::CacheKeyCompare)
		schema.defineTagCompare(&SwapDmi::DefaultCacheKeyLogic::CacheKeyCompare)
		
		schema.defineMainKeyValid(&SwapDmi::DefaultCacheKeyLogic::CacheKeyValidValue)
		schema.defineTagValid(&SwapDmi::DefaultCacheKeyLogic::CacheKeyValidValue)
		schema.defineMainKeyUnique(&SwapDmi::DefaultCacheKeyLogic::CacheKeyUniqueId)
		
		self
	end
	
	CacheKeyValidValue = Proc.new do |ki|
		if ki.nil?
			false
		elsif SwapDmi::CacheKey.wildcard?(ki)
			false
		else case ki
			when Numeric then true
			when String then true
			when Symbol then true
			when Module then true
			else false
		end end
	end
	
	CacheKeyValidId = Proc.new do |k|
		case k
			when SwapDmi::CacheKey then k.isValid?
			else SwapDmi::DefaultCacheKeyLogic::CacheKeyValidValue.call(k) 
		end
	end
	
	CacheKeyUniqueId = CacheKeyValidValue
	
	CacheKeyClean = Proc.new do |ki|
		case ki
			when Numeric then ki
			else ki.to_s.downcase.strip.to_sym 
		end
	end
	
	CacheKeyCompare = Proc.new do |ka,kb|
		conds = [
			Proc.new {|a,b| SwapDmi::CacheKey.wildcard?(a)},
			Proc.new {|a,b| SwapDmi::CacheKey.wildcard?(b)}, 
			Proc.new {|a,b| a == b},
			Proc.new {|a,b| a.to_s =~ /#{b.to_s}/i ? true : false},
			Proc.new {|a,b| b.to_s =~ /#{a.to_s}/i ? true : false},
		]
	
		matches = conds.map do |cond| 
			begin
				cond.call(ka,kb)
			rescue
				false
			end
		end
		matches.include?(true)
	end
	
end end