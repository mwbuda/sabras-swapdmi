


module SwapDmi

	#TODO: integrity errors
	
	#TODO: support subkeys
	# eg if defined entry a,b,c; can also have entry a,b,c,d
	# acommplish by abolishing nil keys, and using nil as placeholder for entry at depth
	
	class HierarchicalIndex
			
		HierachicalIndexError < StandardError
		
		def initialize()
			@data = Hash.new {|h,k| h[k] = Hash.new(&h.default_proc)}
		end
		
		def set(keys, v)
			root = @data
			ckeys = 
			keys[0..-2].each {|k| root = root[k]}
			root[keys[-1]] = v
		end
		
		def get(ks)
			root = @data
			ks[0..-2].each {|k| root = root[k]}
			root.has_key?(ks[-1]) ? root[ks[-1]] : nil
		end
		
		def [](*ks)
			self.get(ks)
		end
		
		def has?(*ks)
			root = @data
			ks[0..-2].each {|k| root = root[k]}
			root.has_key?(ks[-1])
		end
		
	end
	
	
	
end

