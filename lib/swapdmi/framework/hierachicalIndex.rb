


module SwapDmi

	class HierachicalIndexError < StandardError
		
	end
	
	class HierarchicalIndex

		def self.validateKeys(*keys)
			tests = [
				Proc.new {|keys| keys.nil? ? 'nil key set' : nil},
				Proc.new {|keys| keys.empty? ? 'empty key set' : nil},
				Proc.new do |keys|
					ckeys = keys.compact
					(ckeys.size != keys.size) ? 'nil key set items' : nil
				end,
			]
			tests.each {|test| tv = test.call(keys) ; return tv unless tv.nil?}
			nil
		end
		
		def self.validKeys?(*keys)
			!self.validateKeys(*keys).nil?
		end
		
		def initialize()
			@data = Hash.new {|h,k| h[k] = Hash.new(&h.default_proc)}
		end
		
		def set(keys, v)
			testKeys = self.class.validateKeys(*keys)
			raise HierachicalIndexError.new(testKeys) unless testKeys.nil?
			
			root = @data
			keys.each {|k| root = root[k]}
			root[nil] = v
		end
		
		def get(ks)
			root = @data
			ks.each {|k| root = root[k]}
			root.has_key?(nil) ? root[nil] : nil
		end
		
		def [](*ks)
			self.get(ks)
		end
		
		def has?(*ks)
			root = @data
			ks.each {|k| root = root[k]}
			root.has_key?(nil)
		end
		
	end
	
	
	
end

