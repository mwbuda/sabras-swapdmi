
#TODO: delete me
require 'action_controller'

module SwapDmi
	
	# a very basic proxy object to setup dynamic delegate behavior
	#	works with Registry instances & TrackClassHierarchy classes 
	class ProxyObject < BasicObject
		
		def initialize(registry, key = nil, &keyproc)
			#TODO delete me
			$railsLogger.debug("create SwapDmi Proxy => (#{registry}.#{keyproc ? '???' : key} <= #{keyproc})")
			
			@registry = registry
			@filters = {}
			
			unless keyproc
				@key = idValue(key)
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
			
			unless @mutable && @setkey
					@key = idValue( self.instance_exec(&@keyproc) )
					@setkey = true
					@key
			else
					@key
			end
		end
		
		def proxyObjectDelegate()
			key = self.proxyObjectKey
			res = @registry[key]
			
			#TODO: delete me
			$railsLogger.debug("proxy delegate: #{@registry} => #{key}::#{key.class} => #{res}")
			res
		end
			
		def idValue(rawid)
			$railsLogger.debug("proxy kludge swap dmi id value (#{rawid})")
			SwapDmi.idValue(rawid)
		end
			
		def method_missing(method, *args, &proc)
			#TODO delete me
			$railsLogger.debug("proxy delegate: call #{method}")
			$railsLogger.debug("proxy delegate: filters for #{method}? => #{!@filters[method].nil?}")
			
			filter = @filters[method]
			self.instance_exec(method, *args, &filter) unless filter.nil?
			
			#TODO delete me
			$railsLogger.debug("proxy delegate: ran filter for #{method}")
			
			self.proxyObjectDelegate.send(method, *args, &proc) 
		end 
	end
	
	ProxyObject::SwapDmi = self
	
end
