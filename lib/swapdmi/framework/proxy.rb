
#TODO: delete me
require 'action_controller'

module SwapDmi
	
	# a very basic proxy object to setup dynamic delegate behavior
	#	works with Registry instances & TrackClassHierarchy classes 
	class ProxyObject < BasicObject
		
		def initialize(registry, key = nil, &keyproc)
			@registry = registry
			@filters = {}
			
			unless keyproc
				@key = idValue(key)
				@mutable = false
				@setkey = true
			else
				@keyproc = keyproc
				@mutable = key ? true : false
				@setkey = false	
			end
		end
		
		def withProxyPreFilter(methodName, &filter)
			@filters[methodName] = filter
			self
		end
		
		def proxyObjectKey()
			return @key unless @keyproc
			
			unless @setkey
					@key = idValue( self.instance_exec(&@keyproc) )
					@setkey = !@mutable
					@key
			else
					@key
			end
		end
		
		def proxyObjectDelegate()
			key = self.proxyObjectKey
			@registry[key]
		end
			
		def idValue(rawid)
			SwapDmi.idValue(rawid)
		end
			
		def method_missing(method, *args, &proc)
			delegate = self.proxyObjectDelegate
			
			filter = @filters[method]
			self.instance_exec(delegate, *args, &filter) unless filter.nil?
			
			delegate.send(method, *args, &proc) 
		end 
	end
	
	ProxyObject::SwapDmi = self
	
end
