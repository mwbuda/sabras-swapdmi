
module SwapDmi
	
	#TODO: subcontext/extend-context feature,
	#	where a Context instance will delegate to another if missing impl, config, etc
	class ContextOfUse
		extend TrackClassHierarchy
		extend HasConfig
		
		DefaultContextId = :default 
		DefaultImplId = :default
		
		def initialize(id = :default)
			self.assignId(id)
				
			if self.default?
				dcxt = self
				@dataSources = Hash.new {|h,k| h[k] = k.new(dcxt)}
				@impls = {:default => SwapDmi::ModelImpl.default}
			else
				@impls = {}
				@dataSources = {}
			end
		end
		
		def setImpl(k, implk)
			ck, ci = implk.nil? ? [:default,k] : [k,implk]
			@impls[ck] = ci
			self
		end
		
		def defineDataSource(dsClass, sundry = {})
			dsClass.new(self,sundry)
			self
		end
		def assignDataSource(dataSource)
			throw :misMatchedContext if dataSource.context != self
			@dataSources[dataSource.class] = dataSource
			self
		end
		
		def impl(k = :default)
			mi = SwapDmi::ModelImpl[ @impls[SwapDmi.idValue(k)] ]
			mi.ready! unless mi.nil?
			mi
		end
		
		def impls()
			res = {}
			@impls.each do |k,ik| 
				mi = SwapDmi::ModelImpl[ik]
				mi.ready! unless mi.nil?
				res[k] = mi
			end
			res
		end
		
		def dataSources()
			res = @dataSources.dup
		end
		
		def dataSource(dsClass)
			@dataSources[dsClass]
		end
		
		def [](dsClass)
			self.dataSource(dsClass)
		end
	end
	
	DefaultContextOfUse = SwapDmi::ContextOfUse.new
	
	
end

