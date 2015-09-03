
#
# add logging capability
# 
#
#
#
module SwapDmi
	SwapDmi.declareExtension(:logging) 
	
	DefaultLogging = Proc.new {|level, m| puts "#{level}: #{m}"}
	
	class Logger
		extend TrackClassHierarchy
		
		def initialize(id,&behavior)
			assignId(id)
			@func = behavior
		end
		
		def log(level,m)
			@func.call(level,m)
		end
		
	end
		
	SwapDmi::Logger.new(:default, &DefaultLogging)
	
	module HasLog
		
		def self.extended(base)
			logTable = Hash.new do |instances,id|
				instances[id] = :default
			end
			base.class_variable_set(:@@logging, logTable)
			base.instance_eval { include SwapDmi::HasLog::Instance }
		end
		
		def logging()
			self.class_variable_get(:@@logging)
		end
		
		def defineLogger(id, logid)
			self.logging[id] = logid
			self
		end
		
		def logger(id)
			logid = self.logging[id]
			SwapDmi::Logger[logid]
		end
		
		module Instance
			def defineLogger(logid)
				self.class.logging[self.id] = logid
				self
			end
			
			def logger()
				logid = self.class.logging[self.id]
				SwapDmi::Logger[logid]
			end
			
			def log(level,m)
				self.logger.log(level,m)
				self
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
		
		def log(level,m)
			self.logger.log(level,m)
		end
	end

	if SwapDmi.hasExtensions?(:sessiontrack)
		class SessionHandling
			extend HasLog
		end
	end
	
end
