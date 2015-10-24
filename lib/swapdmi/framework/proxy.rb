

module SwapDmi
	
	# a very basic proxy object to setup dynamic delegate behavior
	#	works with Registry instances & TrackClassHierarchy classes 
	class ProxyObject < BasicObject
		
		def initialize(registry, key = nil, &keyproc)
			@registry = registry
			@key = key
			@keyproc = keyproc
			@filters = {}
		end
		
		def withProxyPreFilter(methodName, &filter)
			@filters[methodName] = filter
			self
		end
		
		def proxyObjectKey()
			if !@keyproc.nil?
				self.instance_exec(&@keyproc)
			elsif !@key.nil?
				@key
			else
				nil
			end
		end
		
		def proxyObjectDelegate()
			@registry[self.proxyObjectKey]
		end
			
		def method_missing(method, *args, &proc)
			filter = @filters[method]
			self.instance_exec(method, *args, &filter) unless filter.nil?
			self.proxyObjectDelegate().send(method, *args, &proc) 
		end 
	end
	
end
