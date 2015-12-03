
module SwapDmi
	
	module HasConfig
		def self.extended(base)
			base.extend(SwapDmi::HasId) unless SwapDmi::HasId.extends?(base)
			base.instance_eval { include SwapDmi::HasConfig::Instance }
			base.class_variable_set(:@@config, Hash.new {|h,k| h[k] = Hash.new})
		end
		
		def config(instance = self.defaultId)
			configData = self.class_variable_get(:@@config)
			instance.nil? ? configData : configData[instance]
		end
		
		module Instance
			def config()
				root = self.class.config(self.id)
				Rails.logger.debug("access config for object: #{self.id}::#{self.class} => '#{root}'::#{root.class} => \n#{debugCacheContents(root)}")
				
				self.class.config(self.id)
			end	
			
			def debugCacheContents(root = {}, lv = 0)
				return 'NIL' if root.nil?
				
				case root
					when Hash
						indent = "\t" * (lv+1)
						parts = root.map do |k,v|
							"#{k} => #{debugCacheContents(v, lv+1)}"
						end
						"HASH(#{root.size}):\n#{indent}#{parts.join("\n#{indent}")}"
					when Array
						"ARRAY(#{root.size}): #{root.join(', ')}"
					else
						"#{root}::#{root.class}"
				end
			end
			
		end
	end	
	
end

