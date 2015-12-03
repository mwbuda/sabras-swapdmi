
module SwapDmi
	
	module HasConfig
		def self.extended(base)
			base.extend(SwapDmi::HasId) unless SwapDmi::HasId.extends?(base)
			base.instance_eval { include SwapDmi::HasConfig::Instance }
			base.class_variable_set(:@@config, Hash.new {|h,k| h[k] = Hash.new})
		end
		
		def config(instance = self.defaultId)
			configData = self.class_variable_get(:@@config)
			instance.nil? ? configData : configData[SwapDmi.idValue(instance)]
		end
		
		module Instance
			def config()
				self.class.config(self.id)
			end	
			
		end
	end	
	
end

