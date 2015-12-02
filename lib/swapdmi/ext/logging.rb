
require 'logger'

#
# add logging capability, using the std-lib logger library
#
# This extension integrates with the base session handling extension, if that extension is present.
#	SessionHandling instances will have logging
#
# logging is seemlessly supported at model, datasource, context, and impl levels
#
# A simplified 'log' method is provided which uses a default severity of info.
#	this default can be modified at both the instance, class, and masterclass level, and will obey inheritance
# 
# the default configuration simply prints to console.
#
#
module SwapDmi
	SwapDmi.declareExtension(:logging) 
		
	LogRegistry = SwapDmi::Registry.new(Logger)
	LogRegistry.defaultId = :default
	LogRegistry.register(:default, Logger.new(STDOUT))

	module HasLog
		
		def self.extended(base)
			logTable = {}
			base.class_variable_set(:@@logging, logTable)
			base.instance_eval { include SwapDmi::HasLog::Instance }
		end
		
		def defineLogger(id, logid)
			self.class_variable_get(:@@logging)[id] = logid
			self
		end
		
		def logger(id)
			logid = self.class_variable_get(:@@logging)[id]
			logid = SwapDmi::LogRegistry.defaultId if logid.nil?
			SwapDmi::LogRegistry[logid]
		end
		
		def defaultLoggingSeverity=(sev)
			@swapdmi_dfLogSev = sev
		end
		def setDefaultLoggingSeverity(sev)
			self.defaultLoggingSeverity = sev
			self
		end 
		def defaultLoggingSeverity()
			@swapdmi_dfLogSev
		end
		
		module Instance
			attr_accessor :defaultLoggingSeverity
			
			def defineLogger(logid)
				self.class.defineLogger(self.id,logid)
				self
			end
			
			def logger()
				logid = self.class.logger(self.id)
			end
			
			def setDefaultLoggingSeverity(sev)
				self.defaultLoggingSeverity = sev
				self
			end
			
			# log with default value for severity
			#	default severity can be set on object instance, or at the class, superclass, and masterclass level
			#	default severity if nothing is configured is info.
			#	progname & missing message block are considered to be nil. standard behavior with loggers applies
			def log(m)
				sev = Logger::Severity::INFO
				recvs = [self, self.class, self.class.superclass, self.class.masterclass].uniq
				recvs.each do |recv|
					next unless recv.respond_to?(:defaultLoggingSeverity)
					xv = recv.defaultLoggingSeverity
					next if xv.nil?
					sev = xv
					break
				end
				
				self.logger.log(sev, m, nil, &nil)
			end
		end
		
	end
	
	class ContextOfUse
		extend HasLog
	end
	
	class ModelImpl
		extend HasLog
	end
	
	class Model
		def logger()
			self.context.logger
		end
		
		def log(m)
			self.context.log(m)
		end
	end
	
	SwapDmi.activateExtensionHooks(:logging)
end
